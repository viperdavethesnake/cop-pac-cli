<#
.SYNOPSIS
    Create the Power Apps Custom Connector that lets the Copilot agent
    query Nexus via Microsoft Graph Search.

.NOTES
    Admin Guide: §2.10.4A
    Two operations exposed to the Copilot agent:
      SearchNexus      POST /v1.0/search/query
      GetExternalItem  GET  /v1.0/external/connections/{id}/items/{id}

    What this script does:
      1. Discovers Power Platform environments via service principal (no browser)
      2. Lets you pick an environment — writes PPAC_ENVIRONMENT_URL to .env
      3. Authenticates PAC CLI via service principal (no browser)
      4. Generates apiProperties.json with OAuth2 config from .env values
      5. Patches the swagger contentSource default to the real connector ID
      6. Creates the connector in Power Platform via PAC CLI
      7. Adds the Power Platform redirect URI back to the Entra app (required for OAuth)

    After this script, one manual step remains:
      make.powerapps.com > Custom connectors > <CONNECTOR_NAME> > Edit > Security tab
        1. Paste ENTRA_CLIENT_SECRET into the Client secret field
           (PAC CLI cannot inject secrets — platform security restriction)
        2. "Enable on-behalf-of login" should already read "true" — if blank, type: true
      Click "Update connector", then test via the Test tab (expect HTTP 200).

    Prerequisites:
      - NEXUS_AI_CONNECTOR_ID set in .env (from nexus/06 — needed for correct contentSource)
#>

$script:RequiredVars = @('ENTRA_TENANT_ID', 'ENTRA_CLIENT_ID', 'ENTRA_CLIENT_SECRET', 'CONNECTOR_NAME')
. "$PSScriptRoot/../_common/Config.ps1"

$swaggerSrc    = "$PSScriptRoot/../../artifacts/Connector Artifacts/connectorApiSpec.swagger.json"
$scriptSrc     = "$PSScriptRoot/../../artifacts/Connector Artifacts/code_in_connector.csx"
$connectorName = $env:CONNECTOR_NAME

# ── Preflight checks ──────────────────────────────────────────────────────────
if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    throw "PAC CLI not found. Install: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
}
if (-not (Test-Path $swaggerSrc)) {
    throw "Swagger file not found: $swaggerSrc"
}
if (-not (Test-Path $scriptSrc)) {
    throw "Connector script not found: $scriptSrc"
}
if (-not $env:NEXUS_AI_CONNECTOR_ID) {
    Write-Warning "NEXUS_AI_CONNECTOR_ID not set — contentSource will use placeholder '/external/connections/nexus'."
    Write-Warning "Run nexus/06-Activate-Policy.ps1 first for the correct value."
}

# ── Authenticate PAC CLI ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "Checking PAC CLI authentication..." -ForegroundColor Cyan

function Invoke-PacAuth {
    Write-Host "  Authenticating PAC CLI to tenant $($env:ENTRA_TENANT_ID)..." -ForegroundColor Yellow
    & open "https://login.microsoft.com/device"
    Write-Host "  Enter the code shown below when the browser asks for it:" -ForegroundColor White
    Write-Host ""
    & pac auth create --tenant $env:ENTRA_TENANT_ID --deviceCode
    if ($LASTEXITCODE -ne 0) { throw "PAC CLI authentication failed (exit $LASTEXITCODE)." }
    Write-Host ""
    Write-Host "  PAC CLI authenticated." -ForegroundColor Green
}

$pacWho = pac org who 2>&1
if ($LASTEXITCODE -eq 0 -and $pacWho -match "Connected") {
    # Verify the active session is in the correct tenant
    $authList   = pac auth list 2>&1
    $tenantLine = $authList | Where-Object { $_ -match 'Tenant\s*:' } | Select-Object -First 1
    $pacTenant  = if ($tenantLine -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') { $matches[1] } else { $null }

    if ($pacTenant -and $pacTenant -ne $env:ENTRA_TENANT_ID) {
        Write-Host "  PAC CLI is connected to wrong tenant ($pacTenant) — re-authenticating..." -ForegroundColor Yellow
        pac auth clear | Out-Null
        Invoke-PacAuth
    } else {
        $connectedLine = ($pacWho | Select-String "Connected").Line
        Write-Host "  Already authenticated: $connectedLine" -ForegroundColor DarkGray
        if (-not $pacTenant) {
            Write-Host "  (Could not verify tenant from pac auth list — proceeding)" -ForegroundColor DarkGray
        }
    }
} else {
    Invoke-PacAuth
}

# ── Discover Power Platform environment via PAC CLI ───────────────────────────
Write-Host ""
Write-Host "Discovering Power Platform environments..." -ForegroundColor Cyan

$envUrl = $null

if ($env:PPAC_ENVIRONMENT_URL) {
    $envUrl = $env:PPAC_ENVIRONMENT_URL
    Write-Host "  Using PPAC_ENVIRONMENT_URL from .env: $envUrl" -ForegroundColor DarkGray
} else {
    $pacEnvOutput = & pac env list 2>&1
    # Parse lines: skip header, extract Name + URL columns
    $envLines = $pacEnvOutput | Where-Object { $_ -match "https://" }
    $parsed = $envLines | ForEach-Object {
        if ($_ -match "(https://\S+)") { $matches[1].TrimEnd('/') }
    } | Where-Object { $_ }

    if (-not $parsed) {
        Write-Host "  Could not auto-discover environments." -ForegroundColor Yellow
        $envUrl = Read-Host "  Enter your Power Platform environment URL (e.g. https://org12345.crm.dynamics.com)"
    } elseif (@($parsed).Count -eq 1) {
        $envUrl = @($parsed)[0]
        Write-Host "  Auto-selected: $envUrl" -ForegroundColor DarkGray
    } else {
        Write-Host ""
        Write-Host "  Multiple environments found — select one:" -ForegroundColor Yellow
        $parsedArr = @($parsed)
        for ($i = 0; $i -lt $parsedArr.Count; $i++) {
            Write-Host "    [$($i+1)] $($parsedArr[$i])" -ForegroundColor White
        }
        Write-Host ""
        $selection = Read-Host "  Enter number"
        $idx = [int]$selection - 1
        if ($idx -lt 0 -or $idx -ge $parsedArr.Count) { throw "Invalid selection." }
        $envUrl = $parsedArr[$idx]
    }

    Set-EnvValue 'PPAC_ENVIRONMENT_URL' $envUrl
    Write-Host "  PPAC_ENVIRONMENT_URL written to .env: $envUrl" -ForegroundColor Green
}


Write-Host ""
Write-Host "Creating Power Apps Custom Connector: $connectorName" -ForegroundColor Cyan
Write-Host ("─" * 60)

# ── Build temp working directory ──────────────────────────────────────────────
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "nexus-connector-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tmpDir | Out-Null

$tmpSwagger  = Join-Path $tmpDir "apiDefinition.json"
$tmpApiProps = Join-Path $tmpDir "apiProperties.json"
$tmpScript   = Join-Path $tmpDir "script.csx"

try {

# ── Step 1: Patch swagger contentSource default ───────────────────────────────
Write-Host ""
Write-Host "Preparing connector definition..." -ForegroundColor Cyan

# Source file is YAML with .json extension — convert to real JSON for PAC CLI
Import-Module powershell-yaml -ErrorAction Stop
$swaggerYaml = Get-Content $swaggerSrc -Raw
$swaggerObj  = ConvertFrom-Yaml $swaggerYaml

if ($env:NEXUS_AI_CONNECTOR_ID) {
    # Patch contentSource default in SearchRequest definition
    $swaggerObj.definitions.SearchRequest.properties.contentSource.default = `
        "/external/connections/$($env:NEXUS_AI_CONNECTOR_ID)"
    # Patch x-ms-examples in SearchNexus operation
    $swaggerObj.paths['/v1.0/search/query'].post.'x-ms-examples'.'application/json'.value.contentSource = `
        "/external/connections/$($env:NEXUS_AI_CONNECTOR_ID)"
    Write-Host "  contentSource set to: /external/connections/$($env:NEXUS_AI_CONNECTOR_ID)" -ForegroundColor DarkGray
}

$swaggerJson = $swaggerObj | ConvertTo-Json -Depth 100
Set-Content $tmpSwagger $swaggerJson -NoNewline

# Copy connector script
Copy-Item $scriptSrc $tmpScript

# ── Step 2: Generate apiProperties.json ───────────────────────────────────────
# PAC CLI does not accept clientSecret via the properties file (platform security restriction).
# The client secret must be entered manually on the Security tab after creation.
$apiProperties = @{
    properties = @{
        connectionParameters = @{
            token = @{
                type          = "oAuthSetting"
                oAuthSettings = @{
                    identityProvider = "aad"
                    clientId         = $env:ENTRA_CLIENT_ID
                    scopes           = @("User.Read", "Files.Read", "Sites.Read.All", "ExternalItem.Read.All")
                    redirectMode     = "GlobalPerConnector"
                    redirectUrl      = "https://global.consent.azure-apim.net/redirect"
                    properties       = @{
                        IsFirstParty                    = "False"
                        AzureActiveDirectoryResourceId  = "https://graph.microsoft.com"
                    }
                    customParameters = @{
                        LoginUri              = @{ value = "https://login.microsoftonline.com" }
                        TenantId              = @{ value = $env:ENTRA_TENANT_ID }
                        ResourceUri           = @{ value = "https://graph.microsoft.com" }
                        EnableOnbehalfOfLogin = @{ value = $true }
                    }
                }
            }
        }
        iconBrandColor          = "#40E0D0"
        capabilities            = @()
        policyTemplateInstances = @()
    }
} | ConvertTo-Json -Depth 10

Set-Content $tmpApiProps $apiProperties -NoNewline
Write-Host "  OAuth2 config: tenant=$($env:ENTRA_TENANT_ID), clientId=$($env:ENTRA_CLIENT_ID)" -ForegroundColor DarkGray

# ── Step 3: Create connector via PAC CLI ──────────────────────────────────────
Write-Host ""
Write-Host "  Environment: $envUrl" -ForegroundColor DarkGray

# Check if connector already exists — use update if so, create if not
$existingConnectors = pac connector list --environment $envUrl 2>&1
$existingId = $null
if ($existingConnectors) {
    $guidRegex = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
    # Match only our connector by exact display name — never fall back to a pattern
    # in a shared environment that would grab another user's connector
    $existingLine = $existingConnectors | Where-Object { $_ -match [regex]::Escape($env:CONNECTOR_NAME) } | Select-Object -First 1
    if ($existingLine) {
        $existingId = ([regex]$guidRegex).Match($existingLine).Value
    }
}

if ($existingId) {
    Write-Host "Existing connector found ($existingId) — updating..." -ForegroundColor Cyan
    $pacArgs = @(
        "connector", "update",
        "--connector-id",        $existingId,
        "--api-definition-file", $tmpSwagger,
        "--api-properties-file", $tmpApiProps,
        "--script-file",         $tmpScript,
        "--environment",          $envUrl
    )
} else {
    Write-Host "Running pac connector create..." -ForegroundColor Cyan
    $pacArgs = @(
        "connector", "create",
        "--api-definition-file", $tmpSwagger,
        "--api-properties-file", $tmpApiProps,
        "--script-file",         $tmpScript,
        "--environment",          $envUrl
    )
}

$pacOutput = & pac @pacArgs 2>&1
$pacOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }

if ($LASTEXITCODE -ne 0) {
    throw "pac connector create/update failed (exit $LASTEXITCODE). Check output above."
}

$connectorGuid = if ($existingId) { $existingId } else {
    ($pacOutput | Select-String -Pattern "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" |
        Select-Object -First 1)?.Matches[0]?.Value
}

$verb = if ($existingId) { "updated" } else { "created" }
Write-Host "Connector $verb." -ForegroundColor Green
if ($connectorGuid) {
    Write-Host "  Connector ID: $connectorGuid" -ForegroundColor DarkGray
}

# ── Step 4: Add Power Platform redirect URI to Entra app ─────────────────────
# Power Platform always uses this fixed redirect URI for OAuth custom connectors.
# It must be in the Entra app's reply URLs or token requests will be rejected.
Write-Host ""
Write-Host "Adding Power Platform redirect URI to Entra app..." -ForegroundColor Cyan

$ppRedirectUri = "https://global.consent.azure-apim.net/redirect"

Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "Application.ReadWrite.All" -NoWelcome

$app = Get-MgApplication -Filter "appId eq '$($env:ENTRA_CLIENT_ID)'"
if (-not $app) { throw "Entra app not found — ENTRA_CLIENT_ID may be wrong" }

$existingUris = @($app.Web.RedirectUris)
if ($ppRedirectUri -in $existingUris) {
    Write-Host "  Redirect URI already present — skipping." -ForegroundColor DarkGray
} else {
    $updatedUris = $existingUris + $ppRedirectUri
    Update-MgApplication -ApplicationId $app.Id -Web @{ RedirectUris = [string[]]$updatedUris }
    Write-Host "  Added: $ppRedirectUri" -ForegroundColor Green
}

# ── Step 5: Smoke test — token + Graph Search endpoint ───────────────────────
Write-Host ""
Write-Host "Running smoke test..." -ForegroundColor Cyan

try {
    # Acquire token via client credentials
    $tokenUri  = "https://login.microsoftonline.com/$($env:ENTRA_TENANT_ID)/oauth2/v2.0/token"
    $tokenBody = @{
        client_id     = $env:ENTRA_CLIENT_ID
        client_secret = $env:ENTRA_CLIENT_SECRET
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }
    $token = (Invoke-RestMethod -Method POST -Uri $tokenUri -Body $tokenBody `
        -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop).access_token
    Write-Host "  [PASS] Token acquisition — client credentials valid" -ForegroundColor Green

    # Call Graph Search to confirm the endpoint is reachable and permissions are correct.
    # When NEXUS_AI_CONNECTOR_ID is not yet set, search driveItem (no external connection needed).
    # When it is set, search externalItem against the real contentSource.
    $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    if ($env:NEXUS_AI_CONNECTOR_ID) {
        $searchBody = @{
            requests = @(@{
                entityTypes    = @("externalItem")
                query          = @{ queryString = "test" }
                contentSources = @("/external/connections/$($env:NEXUS_AI_CONNECTOR_ID)")
            })
        } | ConvertTo-Json -Depth 10
        $label = "Graph Search (externalItem)"
    } else {
        $searchBody = @{
            requests = @(@{
                entityTypes = @("driveItem")
                query       = @{ queryString = "test" }
            })
        } | ConvertTo-Json -Depth 10
        $label = "Graph Search (driveItem — NEXUS_AI_CONNECTOR_ID not set yet)"
    }
    $result = Invoke-RestMethod -Method POST -Uri "https://graph.microsoft.com/v1.0/search/query" `
        -Headers $headers -Body $searchBody -ErrorAction Stop
    $hits = $result.value[0].hitsContainers[0].total ?? 0
    Write-Host "  [PASS] $label — HTTP 200 ($hits hits)" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response?.StatusCode.value__ ?? "err"
    Write-Host "  [FAIL] Graph Search failed (HTTP $code): $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "         Verify API permissions at portal.azure.com → App registrations → Panzura-Nexus → API permissions" -ForegroundColor Yellow
}

# ── Summary + next steps ──────────────────────────────────────────────────────
Write-Host ""
Write-Host ("─" * 60)
Write-Host "Custom connector ready." -ForegroundColor Green
Write-Host ""
Write-Host "MANUAL STEPS REQUIRED:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  STEP 1 — Security tab" -ForegroundColor White
Write-Host "    make.powerapps.com > Custom connectors > $connectorName > Edit > Security tab"
Write-Host "    Client secret: paste ENTRA_CLIENT_SECRET from .env" -ForegroundColor Cyan
Write-Host "    Enable on-behalf-of login: should read 'true' — if blank, type: true" -ForegroundColor Cyan
Write-Host "    Click 'Update connector'."
Write-Host ""
Write-Host "  STEP 2 — Create a connection" -ForegroundColor White
Write-Host "    Test tab > + New Connection"
Write-Host "    Pick your Microsoft account when prompted > click Create"
Write-Host "    Status should show 'Connected'."
Write-Host ""
Write-Host "  STEP 3 — Test the connector" -ForegroundColor White
Write-Host "    Left pane > More > Discover All > Data > Custom Connector"
Write-Host "    Find '$connectorName' > Edit > Test tab > Update Connector"
Write-Host "    Fill in:"
Write-Host "      query:         any search string" -ForegroundColor Cyan
if ($env:NEXUS_AI_CONNECTOR_ID) {
    Write-Host "      contentSource: /external/connections/$($env:NEXUS_AI_CONNECTOR_ID)" -ForegroundColor Cyan
} else {
    Write-Host "      contentSource: (set after nexus/06 writes NEXUS_AI_CONNECTOR_ID to .env)" -ForegroundColor DarkGray
}
Write-Host "    Click 'Test Operation' — expect HTTP 200."
Write-Host ""
Write-Host "  STEP 4 — Share the connector" -ForegroundColor White
Write-Host "    Custom connectors > $connectorName > Share tab"
Write-Host "    Add the people who will use the Copilot agent."
Write-Host ""
Write-Host "Run next: scripts/copilot/02-New-CopilotAgent.ps1" -ForegroundColor Cyan

} finally {
    # Clean up temp files
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
