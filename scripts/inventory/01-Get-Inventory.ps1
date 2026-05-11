<#
.SYNOPSIS
    Query live state of all Nexus deployment resources and write a snapshot
    to inventory/inventory-YYYYMMDD-HHmmss.json in the project root.

    Checks both configured resources (from .env) AND does a broad name-based
    search for anything containing "panzura" or "nexus" to catch orphans or
    resources created outside these scripts.

    Run at any time — each section is independent and skipped if not yet deployed.
    Re-run after any deployment change to capture the updated state.

.OUTPUTS
    inventory/inventory-<timestamp>.json
    Console summary (PASS / WARN / MISS per resource)
#>

. "$PSScriptRoot/../_common/Config.ps1"

$timestamp   = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
$fileStamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$projectRoot = Resolve-Path "$PSScriptRoot/../../"
$outDir      = Join-Path $projectRoot "inventory"
$outFile     = Join-Path $outDir "inventory-$fileStamp.json"

$inv = [ordered]@{
    timestamp    = $timestamp
    entra        = [ordered]@{}
    broadSearch  = [ordered]@{}
    powerApps    = [ordered]@{}
    nexus        = [ordered]@{}
    cloudfs      = [ordered]@{}
    m365         = [ordered]@{}
}

function Write-Section { param([string]$t) Write-Host ""; Write-Host $t -ForegroundColor Cyan; Write-Host ("─" * 50) }
function Write-Found   { param([string]$t) Write-Host "  [PASS] $t" -ForegroundColor Green }
function Write-Missing { param([string]$t) Write-Host "  [MISS] $t" -ForegroundColor Yellow }
function Write-Warn    { param([string]$t) Write-Host "  [WARN] $t" -ForegroundColor DarkYellow }
function Write-Extra   { param([string]$t) Write-Host "  [XTRA] $t" -ForegroundColor Magenta }

Write-Host ""
Write-Host "Nexus Deployment Inventory — $timestamp" -ForegroundColor White
Write-Host ("═" * 50)

# ── Graph connection (shared by Entra, Broad Search, M365) ───────────────────
$graphConnected = $false
try {
    if ($env:ENTRA_CLIENT_ID -and $env:ENTRA_CLIENT_SECRET) {
        $cred = New-Object System.Management.Automation.PSCredential(
            $env:ENTRA_CLIENT_ID,
            (ConvertTo-SecureString $env:ENTRA_CLIENT_SECRET -AsPlainText -Force)
        )
        Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -ClientSecretCredential $cred -NoWelcome -ErrorAction Stop
        $graphConnected = $true
    }
} catch {
    Write-Host ""
    Write-Warn "Client-secret Graph auth failed — falling back to interactive login"
}
if (-not $graphConnected) {
    try {
        Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "Application.Read.All","Directory.Read.All","Organization.Read.All" -NoWelcome -ErrorAction Stop
        $graphConnected = $true
    } catch {
        Write-Warn "Graph connection failed: $($_.Exception.Message)"
    }
}

# ── Entra ID — configured app ─────────────────────────────────────────────────
Write-Section "Entra ID (configured)"

$inv.entra.tenantId = $env:ENTRA_TENANT_ID

if (-not $graphConnected) {
    Write-Warn "Skipped — Graph not connected"
    $inv.entra.error = "Graph connection failed"
} else {
    try {
        $app = $null
        if ($env:ENTRA_CLIENT_ID) {
            $app = Get-MgApplication -Filter "appId eq '$($env:ENTRA_CLIENT_ID)'" -ErrorAction SilentlyContinue
        }
        if (-not $app -and $env:ENTRA_APP_NAME) {
            $app = Get-MgApplication -Filter "displayName eq '$($env:ENTRA_APP_NAME)'" -ErrorAction SilentlyContinue | Select-Object -First 1
        }

        if ($app) {
            Write-Found "App: $($app.DisplayName) (AppId: $($app.AppId))"

            $secrets = $app.PasswordCredentials | ForEach-Object {
                $daysLeft = [int](($_.EndDateTime - (Get-Date)).TotalDays)
                $status   = if ($daysLeft -lt 0) { "EXPIRED" } elseif ($daysLeft -lt 30) { "EXPIRING SOON" } else { "OK" }
                Write-Found "  Secret: '$($_.DisplayName)' expires $($_.EndDateTime.ToString('yyyy-MM-dd')) ($daysLeft days) [$status]"
                [ordered]@{ name = $_.DisplayName; expires = $_.EndDateTime.ToString('yyyy-MM-dd'); daysLeft = $daysLeft; status = $status }
            }

            $sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ErrorAction SilentlyContinue
            $grants = @(); $roleAssignments = @()
            if ($sp) {
                $grants         = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue
                $roleAssignments = Get-MgServicePrincipalAppRoleAssignment    -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue
                Write-Found "  Service principal: $($sp.Id)"
                Write-Found "  Delegated grants: $($grants.Count)   App role assignments: $($roleAssignments.Count)"
            }

            $inv.entra.app = [ordered]@{
                found              = $true
                displayName        = $app.DisplayName
                appId              = $app.AppId
                objectId           = $app.Id
                createdDateTime    = $app.CreatedDateTime?.ToString('yyyy-MM-dd')
                servicePrincipalId = $sp?.Id
                secrets            = @($secrets)
                delegatedGrants    = $grants.Count
                appRoleAssignments = $roleAssignments.Count
                redirectUris       = @($app.Web.RedirectUris)
            }
        } else {
            Write-Missing "App '$($env:ENTRA_APP_NAME)' not found"
            $inv.entra.app = [ordered]@{ found = $false }
        }
    } catch {
        Write-Warn "Entra query error: $($_.Exception.Message)"
        $inv.entra.error = $_.Exception.Message
    }
}

# ── Broad Search — Entra (any app/SP with panzura or nexus in name) ───────────
Write-Section "Broad Search — Entra (panzura / nexus)"

$inv.broadSearch.entraApps            = @()
$inv.broadSearch.entraServicePrincipals = @()

if (-not $graphConnected) {
    Write-Warn "Skipped — Graph not connected"
} else {
    try {
        # Known-safe patterns — Microsoft-managed, not created by our scripts
        $knownSafe = @(
            'ConnectSyncProvisioning_*'   # Entra Connect V2 sync agent — name contains DC hostname
        )
        function Test-KnownSafe { param([string]$name) $knownSafe | Where-Object { $name -like $_ } }

        # App registrations — search both keywords, deduplicate by AppId
        $seenAppIds = @{}
        foreach ($keyword in @('panzura','nexus')) {
            $results = Get-MgApplication -Search "`"displayName:$keyword`"" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
            foreach ($r in $results) {
                if ($seenAppIds.ContainsKey($r.AppId)) { continue }
                $seenAppIds[$r.AppId] = $true
                $isConfigured = ($r.AppId -eq $env:ENTRA_CLIENT_ID)
                $isSafe       = Test-KnownSafe $r.DisplayName
                $label = if ($isConfigured) { "(configured)" } elseif ($isSafe) { "(known-safe: Microsoft-managed)" } else { "[other]" }
                $color = if ($isConfigured) { "Green" } elseif ($isSafe) { "DarkGray" } else { "Magenta" }
                Write-Host "  [APP]  $($r.DisplayName)  AppId: $($r.AppId)  $label" -ForegroundColor $color
                $inv.broadSearch.entraApps += [ordered]@{
                    displayName = $r.DisplayName
                    appId       = $r.AppId
                    objectId    = $r.Id
                    configured  = $isConfigured
                    knownSafe   = [bool]$isSafe
                }
            }
        }
        if ($inv.broadSearch.entraApps.Count -eq 0) { Write-Missing "No app registrations found matching panzura/nexus" }

        # Service principals — deduplicate by AppId
        $seenSpIds = @{}
        foreach ($keyword in @('panzura','nexus')) {
            $results = Get-MgServicePrincipal -Search "`"displayName:$keyword`"" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
            foreach ($r in $results) {
                if ($seenSpIds.ContainsKey($r.AppId)) { continue }
                $seenSpIds[$r.AppId] = $true
                $isConfigured = ($r.AppId -eq $env:ENTRA_CLIENT_ID)
                $isSafe       = Test-KnownSafe $r.DisplayName
                $label = if ($isConfigured) { "(configured)" } elseif ($isSafe) { "(known-safe: Microsoft-managed)" } else { "[other]" }
                $color = if ($isConfigured) { "Green" } elseif ($isSafe) { "DarkGray" } else { "Magenta" }
                Write-Host "  [SP]   $($r.DisplayName)  AppId: $($r.AppId)  Type: $($r.ServicePrincipalType)  $label" -ForegroundColor $color
                $inv.broadSearch.entraServicePrincipals += [ordered]@{
                    displayName          = $r.DisplayName
                    appId                = $r.AppId
                    objectId             = $r.Id
                    servicePrincipalType = $r.ServicePrincipalType
                    configured           = $isConfigured
                    knownSafe            = [bool]$isSafe
                }
            }
        }
        if ($inv.broadSearch.entraServicePrincipals.Count -eq 0) { Write-Missing "No service principals found matching panzura/nexus" }

    } catch {
        Write-Warn "Broad Entra search error: $($_.Exception.Message)"
        $inv.broadSearch.entraError = $_.Exception.Message
    }
}

# ── Power Apps — configured + broad search ────────────────────────────────────
Write-Section "Power Apps"

$inv.powerApps.environmentUrl = $env:PPAC_ENVIRONMENT_URL
$inv.powerApps.allConnectors  = @()

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Warn "PAC CLI not found — skipping"
    $inv.powerApps.error = "PAC CLI not installed"
} elseif (-not $env:PPAC_ENVIRONMENT_URL) {
    Write-Missing "PPAC_ENVIRONMENT_URL not set"
} else {
    try {
        $rawLines = pac connector list --environment $env:PPAC_ENVIRONMENT_URL 2>&1

        # Parse all connectors — each data row has a GUID
        $guidRegex = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
        $dataLines = $rawLines | Where-Object { $_ -match $guidRegex -and $_ -notmatch '^Connected' }

        foreach ($line in $dataLines) {
            $id   = ([regex]$guidRegex).Match($line).Value
            # Name is everything before the GUID, trimmed
            $name = ($line -replace $guidRegex, '').Trim(' ─-│|')
            if (-not $name) { $name = "(unknown)" }

            $isConfigured = ($name -match [regex]::Escape($env:CONNECTOR_NAME)) -or ($id -eq '20bdb32b-2e4b-f111-bec5-000d3a5b4866')
            $isPanzuraNexus = $name -match 'panzura|nexus'

            if ($isConfigured) {
                Write-Found "Connector: $name (ID: $id) (configured)"
            } elseif ($isPanzuraNexus) {
                Write-Extra "Connector: $name (ID: $id) [other — not ours]"
            }

            $inv.powerApps.allConnectors += [ordered]@{
                name        = $name
                id          = $id
                configured  = $isConfigured
                isPanzuraNexus = $isPanzuraNexus
            }
        }

        $configured = $inv.powerApps.allConnectors | Where-Object { $_.configured }
        $unexpected = $inv.powerApps.allConnectors | Where-Object { $_.isPanzuraNexus -and -not $_.configured }

        if (-not $configured) {
            Write-Missing "Configured connector '$($env:CONNECTOR_NAME)' not found"
        }
        if (-not $unexpected -and -not $configured) {
            Write-Missing "No connectors matching panzura/nexus found in environment"
        }

    } catch {
        Write-Warn "PAC CLI error: $($_.Exception.Message)"
        $inv.powerApps.error = $_.Exception.Message
    }
}

# ── Nexus VM ──────────────────────────────────────────────────────────────────
Write-Section "Nexus VM"

$inv.nexus.ip = $env:NEXUS_IP

if (-not $env:NEXUS_IP) {
    Write-Missing "NEXUS_IP not set — not yet deployed"
    $inv.nexus.reachable = $false
} else {
    try {
        Invoke-WebRequest -Uri "https://$($env:NEXUS_IP)" -TimeoutSec 5 -SkipCertificateCheck -ErrorAction Stop | Out-Null
        Write-Found "Host reachable: $($env:NEXUS_IP)"
        $inv.nexus.reachable = $true
    } catch {
        if ($_.Exception.Message -match "SSL|certificate|TLS") {
            Write-Found "Host reachable (self-signed cert): $($env:NEXUS_IP)"
            $inv.nexus.reachable = $true
        } else {
            Write-Missing "Host not reachable: $($env:NEXUS_IP)"
            $inv.nexus.reachable = $false
        }
    }
}

$inv.nexus.plugins = [ordered]@{
    storagePluginId = $env:NEXUS_STORAGE_PLUGIN_ID
    aiPluginId      = $env:NEXUS_AI_PLUGIN_ID
    iamPluginId     = $env:NEXUS_IAM_PLUGIN_ID
    policyId        = $env:NEXUS_POLICY_ID
    aiConnectorId   = $env:NEXUS_AI_CONNECTOR_ID
}
foreach ($pair in $inv.nexus.plugins.GetEnumerator()) {
    if ($pair.Value) { Write-Found "$($pair.Key): $($pair.Value)" }
    else             { Write-Missing "$($pair.Key): not yet set" }
}

# ── CloudFS ───────────────────────────────────────────────────────────────────
Write-Section "CloudFS"

$inv.cloudfs.masterNode = $env:CLOUDFS_MASTER_NODE
$inv.cloudfs.version    = $env:CLOUDFS_VERSION

if (-not $env:CLOUDFS_MASTER_NODE) {
    Write-Missing "CLOUDFS_MASTER_NODE not set — not yet deployed"
    $inv.cloudfs.reachable = $false
} else {
    try {
        $ping = Test-Connection -ComputerName $env:CLOUDFS_MASTER_NODE -Count 1 -Quiet -ErrorAction Stop
        if ($ping) { Write-Found "Master node reachable: $($env:CLOUDFS_MASTER_NODE)"; $inv.cloudfs.reachable = $true }
        else        { Write-Missing "Master node not responding: $($env:CLOUDFS_MASTER_NODE)"; $inv.cloudfs.reachable = $false }
    } catch {
        Write-Missing "Master node unreachable: $($env:CLOUDFS_MASTER_NODE)"
        $inv.cloudfs.reachable = $false
    }
}

# ── M365 Copilot ──────────────────────────────────────────────────────────────
Write-Section "M365 Copilot"

try {
    # SP token may lack Organization.Read.All — reconnect interactively if needed
    $skus = $null
    try {
        $skus = Get-MgSubscribedSku -ErrorAction Stop
    } catch {
        if ($_.Exception.Message -match "Authorization|privilege|Insufficient") {
            Write-Host "  SP token insufficient for license query — reconnecting interactively..." -ForegroundColor DarkGray
            Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "Organization.Read.All","ExternalConnection.Read.All" -NoWelcome -ErrorAction Stop
            $skus = Get-MgSubscribedSku -ErrorAction Stop
        } else { throw }
    }

    $copilotSkus = $skus | Where-Object { $_.SkuPartNumber -match 'copilot' }
    if ($copilotSkus) {
        $inv.m365.licenses = @($copilotSkus | ForEach-Object {
            $avail = $_.PrepaidUnits.Enabled - $_.ConsumedUnits
            Write-Found "$($_.SkuPartNumber): $avail available of $($_.PrepaidUnits.Enabled)"
            [ordered]@{ sku = $_.SkuPartNumber; total = $_.PrepaidUnits.Enabled; consumed = $_.ConsumedUnits; available = $avail }
        })
    } else {
        Write-Missing "No Copilot SKUs found in tenant"
        $inv.m365.licenses = @()
    }

    # Graph connector state
    if ($env:NEXUS_AI_CONNECTOR_ID) {
        try {
            $conn = Invoke-MgGraphRequest -Method GET `
                -Uri "https://graph.microsoft.com/v1.0/external/connections/$($env:NEXUS_AI_CONNECTOR_ID)" `
                -ErrorAction Stop
            Write-Found "Graph connector '$($env:NEXUS_AI_CONNECTOR_ID)': state=$($conn.state)"
            $inv.m365.graphConnector = [ordered]@{ found = $true; id = $env:NEXUS_AI_CONNECTOR_ID; state = $conn.state; name = $conn.name }
        } catch {
            Write-Warn "Graph connector '$($env:NEXUS_AI_CONNECTOR_ID)' not found or not yet active"
            $inv.m365.graphConnector = [ordered]@{ found = $false; id = $env:NEXUS_AI_CONNECTOR_ID }
        }
    } else {
        Write-Missing "NEXUS_AI_CONNECTOR_ID not set — Graph connector not yet created"
        $inv.m365.graphConnector = [ordered]@{ found = $false; reason = "NEXUS_AI_CONNECTOR_ID not set" }
    }

    # Broad search — any Graph external connections with panzura/nexus in name
    try {
        $allConns = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/external/connections" -ErrorAction Stop
        $panzuraConns = $allConns.value | Where-Object { $_.name -match 'panzura|nexus' -or $_.id -match 'panzura|nexus' }
        if ($panzuraConns) {
            Write-Host ""
            Write-Host "  Broad search — Graph external connections:" -ForegroundColor Cyan
            $inv.m365.allGraphConnectors = @($panzuraConns | ForEach-Object {
                $isConfigured = ($_.id -eq $env:NEXUS_AI_CONNECTOR_ID)
                $label = if ($isConfigured) { "(configured)" } else { "[other]" }
                $color = if ($isConfigured) { "Green" } else { "DarkGray" }
                Write-Host "    $($_.name)  id: $($_.id)  state: $($_.state)  $label" -ForegroundColor $color
                [ordered]@{ name = $_.name; id = $_.id; state = $_.state; configured = $isConfigured }
            })
        } else {
            $inv.m365.allGraphConnectors = @()
        }
    } catch {
        $inv.m365.graphConnectorSearchError = $_.Exception.Message
    }

} catch {
    Write-Warn "M365 query failed: $($_.Exception.Message)"
    $inv.m365.error = $_.Exception.Message
}

# ── Write output file ─────────────────────────────────────────────────────────
$json = $inv | ConvertTo-Json -Depth 10
Set-Content $outFile $json -Encoding UTF8

Write-Host ""
Write-Host ("═" * 50)
Write-Host "Inventory written to: $outFile" -ForegroundColor Green
Write-Host ""

# Flag any unexpected resources
$unexpected = @()
$unexpected += $inv.broadSearch.entraApps              | Where-Object { -not $_.configured -and -not $_.knownSafe }
$unexpected += $inv.broadSearch.entraServicePrincipals | Where-Object { -not $_.configured -and -not $_.knownSafe }
$unexpected += $inv.powerApps.allConnectors            | Where-Object { $_.isPanzuraNexus -and -not $_.configured }
$unexpected += $inv.m365.allGraphConnectors            | Where-Object { -not $_.configured }

if ($unexpected.Count -gt 0) {
    Write-Host "$($unexpected.Count) other panzura/nexus resource(s) found in this environment (not ours) — see [XTRA] items above." -ForegroundColor DarkGray
} else {
    Write-Host "No other panzura/nexus resources found in this environment." -ForegroundColor DarkGray
}
