<#
.SYNOPSIS
    Query live state of all Nexus deployment resources and write a snapshot
    to inventory/inventory-YYYYMMDD-HHmmss.json in the project root.

    Shows resources scoped to the current user where possible (connectors,
    agents) so shared-tenant noise doesn't obscure what you own.

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
    identity     = [ordered]@{}
    entra        = [ordered]@{}
    broadSearch  = [ordered]@{}
    powerApps    = [ordered]@{}
    copilot      = [ordered]@{}
    nexus        = [ordered]@{}
    cloudfs      = [ordered]@{}
    m365         = [ordered]@{}
}

function Write-Section { param([string]$t) Write-Host ""; Write-Host $t -ForegroundColor Cyan; Write-Host ("─" * 50) }
function Write-Found   { param([string]$t) Write-Host "  [PASS] $t" -ForegroundColor Green }
function Write-Missing { param([string]$t) Write-Host "  [MISS] $t" -ForegroundColor Yellow }
function Write-Warn    { param([string]$t) Write-Host "  [WARN] $t" -ForegroundColor DarkYellow }
function Write-Extra   { param([string]$t) Write-Host "  [XTRA] $t" -ForegroundColor DarkGray }
function Write-Info    { param([string]$t) Write-Host "  [INFO] $t" -ForegroundColor DarkGray }

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
        Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "Application.Read.All","Directory.Read.All","Organization.Read.All","User.Read" -NoWelcome -ErrorAction Stop
        $graphConnected = $true
    } catch {
        Write-Warn "Graph connection failed: $($_.Exception.Message)"
    }
}

# ── Current identity ──────────────────────────────────────────────────────────
$myUpn         = $null
$myAadObjectId = $null

Write-Section "Current Identity"

if (-not $graphConnected) {
    Write-Warn "Graph not connected — cannot resolve user identity"
} else {
    try {
        $ctx = Get-MgContext
        $myUpn = $ctx.Account
        if ($myUpn) {
            # Use "me" endpoint — avoids needing User.ReadBasic.All for UPN lookup
            $me = Get-MgUser -UserId "me" -Property Id,DisplayName,UserPrincipalName -ErrorAction SilentlyContinue
            $myAadObjectId = $me?.Id
            Write-Found "Signed in as: $myUpn"
            Write-Info  "Entra Object ID: $myAadObjectId"
        } else {
            Write-Warn "Running as service principal (client-secret auth) — owner-filtered queries will be skipped"
        }
        $inv.identity.upn          = $myUpn
        $inv.identity.aadObjectId  = $myAadObjectId
        $inv.identity.tenantId     = $env:ENTRA_TENANT_ID
    } catch {
        Write-Warn "Could not resolve current user: $($_.Exception.Message)"
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
            # Try standard filter first; fall back to search if token lacks delegated Application.Read.All
            $app = Get-MgApplication -Filter "appId eq '$($env:ENTRA_CLIENT_ID)'" -ErrorAction SilentlyContinue
            if (-not $app) {
                $app = Get-MgApplication -Search "`"appId:$($env:ENTRA_CLIENT_ID)`"" -ConsistencyLevel eventual -ErrorAction SilentlyContinue | Select-Object -First 1
            }
        }

        if ($app) {
            Write-Found "App: $($app.DisplayName)  AppId: $($app.AppId)  ObjectId: $($app.Id)"

            # Secrets
            if ($app.PasswordCredentials) {
                foreach ($s in $app.PasswordCredentials) {
                    $daysLeft = [int](($s.EndDateTime - (Get-Date)).TotalDays)
                    $status   = if ($daysLeft -lt 0) { "EXPIRED" } elseif ($daysLeft -lt 30) { "EXPIRING SOON" } else { "OK" }
                    $color    = if ($status -eq "OK") { "Green" } elseif ($status -eq "EXPIRING SOON") { "Yellow" } else { "Red" }
                    Write-Host "  [PASS] Secret: '$($s.DisplayName)'  hint: $($s.Hint)***  expires: $($s.EndDateTime.ToString('yyyy-MM-dd')) ($daysLeft days) [$status]" -ForegroundColor $color
                }
            } else {
                Write-Missing "No client secrets"
            }

            # Redirect URIs
            $redirectUris = @($app.Web?.RedirectUris) + @($app.Spa?.RedirectUris) | Where-Object { $_ }
            if ($redirectUris) {
                foreach ($uri in $redirectUris) { Write-Info "Redirect URI: $uri" }
            } else {
                Write-Missing "No redirect URIs registered"
            }

            # Permissions summary
            $sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ErrorAction SilentlyContinue
            if ($sp) {
                $grants          = @(Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue)
                $roleAssignments = @(Get-MgServicePrincipalAppRoleAssignment    -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue)
                Write-Info "Service principal: $($sp.Id)"
                Write-Info "App permissions (roles): $($roleAssignments.Count)   Delegated permissions (scopes): $($grants.Count)"
            }

            $inv.entra.app = [ordered]@{
                found              = $true
                displayName        = $app.DisplayName
                appId              = $app.AppId
                objectId           = $app.Id
                createdDateTime    = $app.CreatedDateTime?.ToString('yyyy-MM-dd')
                servicePrincipalId = $sp?.Id
                secrets            = @($app.PasswordCredentials | ForEach-Object {
                    $daysLeft = [int](($_.EndDateTime - (Get-Date)).TotalDays)
                    [ordered]@{ name = $_.DisplayName; hint = "$($_.Hint)***"; expires = $_.EndDateTime.ToString('yyyy-MM-dd'); daysLeft = $daysLeft; status = if ($daysLeft -lt 0) { "EXPIRED" } elseif ($daysLeft -lt 30) { "EXPIRING SOON" } else { "OK" } }
                })
                redirectUris       = @($redirectUris)
                appRoleAssignments = $roleAssignments?.Count
                delegatedGrants    = $grants?.Count
            }
        } else {
            Write-Missing "App not found — ENTRA_CLIENT_ID not set or app not registered yet"
            $inv.entra.app = [ordered]@{ found = $false }
        }
    } catch {
        Write-Warn "Entra query error: $($_.Exception.Message)"
        $inv.entra.error = $_.Exception.Message
    }
}

# ── Broad Search — Entra (any app/SP with panzura or nexus in name) ───────────
Write-Section "Broad Search — Entra (panzura / nexus)"

$inv.broadSearch.entraApps              = @()
$inv.broadSearch.entraServicePrincipals = @()

if (-not $graphConnected) {
    Write-Warn "Skipped — Graph not connected"
} else {
    try {
        $knownSafe = @( 'ConnectSyncProvisioning_*' )
        function Test-KnownSafe { param([string]$name) $knownSafe | Where-Object { $name -like $_ } }

        $seenAppIds = @{}
        foreach ($keyword in @('panzura','nexus')) {
            $results = Get-MgApplication -Search "`"displayName:$keyword`"" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
            foreach ($r in $results) {
                if ($seenAppIds.ContainsKey($r.AppId)) { continue }
                $seenAppIds[$r.AppId] = $true
                $isConfigured = ($r.AppId -eq $env:ENTRA_CLIENT_ID)
                $isSafe       = Test-KnownSafe $r.DisplayName
                $label = if ($isConfigured) { "(configured)" } elseif ($isSafe) { "(known-safe)" } else { "[other]" }
                $color = if ($isConfigured) { "Green" } else { "DarkGray" }
                Write-Host "  [APP]  $($r.DisplayName)  AppId: $($r.AppId)  $label" -ForegroundColor $color
                $inv.broadSearch.entraApps += [ordered]@{ displayName = $r.DisplayName; appId = $r.AppId; objectId = $r.Id; configured = $isConfigured; knownSafe = [bool]$isSafe }
            }
        }
        if ($inv.broadSearch.entraApps.Count -eq 0) { Write-Missing "No app registrations found matching panzura/nexus" }

        $seenSpIds = @{}
        foreach ($keyword in @('panzura','nexus')) {
            $results = Get-MgServicePrincipal -Search "`"displayName:$keyword`"" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
            foreach ($r in $results) {
                if ($seenSpIds.ContainsKey($r.AppId)) { continue }
                $seenSpIds[$r.AppId] = $true
                $isConfigured = ($r.AppId -eq $env:ENTRA_CLIENT_ID)
                $isSafe       = Test-KnownSafe $r.DisplayName
                $label = if ($isConfigured) { "(configured)" } elseif ($isSafe) { "(known-safe)" } else { "[other]" }
                $color = if ($isConfigured) { "Green" } else { "DarkGray" }
                Write-Host "  [SP]   $($r.DisplayName)  AppId: $($r.AppId)  $label" -ForegroundColor $color
                $inv.broadSearch.entraServicePrincipals += [ordered]@{ displayName = $r.DisplayName; appId = $r.AppId; objectId = $r.Id; servicePrincipalType = $r.ServicePrincipalType; configured = $isConfigured; knownSafe = [bool]$isSafe }
            }
        }
        if ($inv.broadSearch.entraServicePrincipals.Count -eq 0) { Write-Missing "No service principals found matching panzura/nexus" }

    } catch {
        Write-Warn "Broad Entra search error: $($_.Exception.Message)"
        $inv.broadSearch.entraError = $_.Exception.Message
    }
}

# ── Power Apps — configured connector + my connectors ────────────────────────
Write-Section "Power Apps"

$inv.powerApps.environmentUrl = $env:PPAC_ENVIRONMENT_URL
$inv.powerApps.configuredConnector = $null
$inv.powerApps.myConnectors        = @()

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Warn "PAC CLI not found — skipping"
    $inv.powerApps.error = "PAC CLI not installed"
} elseif (-not $env:PPAC_ENVIRONMENT_URL) {
    Write-Missing "PPAC_ENVIRONMENT_URL not set"
} else {
    # ── Configured connector (exact name match from .env) ─────────────────────
    try {
        $rawLines  = pac connector list --environment $env:PPAC_ENVIRONMENT_URL 2>&1
        $guidRegex = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
        $dataLines = $rawLines | Where-Object { $_ -match $guidRegex -and $_ -notmatch '^Connected' }

        $configuredLine = $dataLines | Where-Object { $_ -match [regex]::Escape($env:CONNECTOR_NAME) } | Select-Object -First 1
        if ($configuredLine) {
            $connId = ([regex]$guidRegex).Match($configuredLine).Value
            Write-Found "Configured connector '$($env:CONNECTOR_NAME)' (ID: $connId)"
            $inv.powerApps.configuredConnector = [ordered]@{ found = $true; name = $env:CONNECTOR_NAME; id = $connId }
        } else {
            Write-Missing "Configured connector '$($env:CONNECTOR_NAME)' not found"
            $inv.powerApps.configuredConnector = [ordered]@{ found = $false; name = $env:CONNECTOR_NAME }
        }
    } catch {
        Write-Warn "PAC CLI connector list failed: $($_.Exception.Message)"
    }

    # ── My connectors (all connectors owned by current user) ──────────────────
    if ($myAadObjectId) {
        try {
            Add-PowerAppsAccount -TenantID $env:ENTRA_TENANT_ID -Endpoint prod 2>&1 | Out-Null
            $orgHost   = ([uri]$env:PPAC_ENVIRONMENT_URL).Host.Split('.')[0]
            $targetEnv = Get-AdminEnvironment | Where-Object {
                $_.Internal.properties.linkedEnvironmentMetadata.instanceUrl -match $orgHost
            } | Select-Object -First 1

            if ($targetEnv) {
                $allAdminConnectors = @(Get-AdminConnector -EnvironmentName $targetEnv.EnvironmentName -ErrorAction SilentlyContinue)
                $myConnectors = $allAdminConnectors | Where-Object {
                    $owner = $_.CreatedBy
                    $owner -and ($owner.id -eq $myAadObjectId -or $owner.objectId -eq $myAadObjectId -or $owner.userPrincipalName -eq $myUpn)
                }

                Write-Host ""
                if ($myConnectors) {
                    Write-Host "  My connectors in this environment ($myUpn):" -ForegroundColor Cyan
                    foreach ($c in $myConnectors) {
                        $isConfigured = ($c.DisplayName -eq $env:CONNECTOR_NAME)
                        $label = if ($isConfigured) { " (configured)" } else { "" }
                        $color = if ($isConfigured) { "Green" } else { "DarkGray" }
                        Write-Host "    $($c.DisplayName)  ID: $($c.ConnectorName)$label" -ForegroundColor $color
                    }
                    $inv.powerApps.myConnectors = @($myConnectors | ForEach-Object {
                        [ordered]@{ displayName = $_.DisplayName; id = $_.ConnectorName; configured = ($_.DisplayName -eq $env:CONNECTOR_NAME) }
                    })
                } else {
                    Write-Info "No connectors owned by $myUpn in this environment"
                }
            } else {
                Write-Warn "Could not resolve environment from PPAC_ENVIRONMENT_URL"
            }
        } catch {
            Write-Warn "Owner-filtered connector query failed: $($_.Exception.Message)"
        }
    } else {
        Write-Info "User identity not resolved — skipping owner-filtered connector list"
    }
}

# ── Copilot Studio Agents ─────────────────────────────────────────────────────
Write-Section "Copilot Studio Agents"

$inv.copilot.agentName  = $env:COPILOT_AGENT_NAME
$inv.copilot.myAgents   = @()

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Warn "PAC CLI not found — skipping"
} elseif (-not $env:PPAC_ENVIRONMENT_URL) {
    Write-Missing "PPAC_ENVIRONMENT_URL not set"
} else {
    try {
        $agentLines = pac copilot list --environment $env:PPAC_ENVIRONMENT_URL 2>&1
        $guidRegex  = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
        $agentData  = $agentLines | Where-Object { $_ -match $guidRegex -and $_ -notmatch '^Connected' -and $_ -notmatch '^Microsoft' }

        if ($agentData) {
            foreach ($line in $agentData) {
                $id   = ([regex]$guidRegex).Match($line).Value
                # pac copilot list outputs a multi-column table; take only the first column (name)
                $name = ($line -split '\s{2,}')[0].Trim()
                $isConfigured = ($env:COPILOT_AGENT_NAME -and $name -match [regex]::Escape($env:COPILOT_AGENT_NAME))
                if ($isConfigured) {
                    Write-Found "Agent: $name (ID: $id) (configured)"
                } else {
                    Write-Extra "Agent: $name (ID: $id) [other]"
                }
                $inv.copilot.myAgents += [ordered]@{ name = $name; id = $id; configured = $isConfigured }
            }
            if (-not ($inv.copilot.myAgents | Where-Object { $_.configured })) {
                if ($env:COPILOT_AGENT_NAME) {
                    Write-Missing "Configured agent '$($env:COPILOT_AGENT_NAME)' not found"
                }
            }
        } else {
            Write-Missing "No agents found in environment"
        }
    } catch {
        Write-Warn "Copilot agent query failed: $($_.Exception.Message)"
        $inv.copilot.error = $_.Exception.Message
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

    try {
        $allConns     = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/external/connections" -ErrorAction Stop
        $panzuraConns = $allConns.value | Where-Object { $_.name -match 'panzura|nexus' -or $_.id -match 'panzura|nexus' }
        if ($panzuraConns) {
            Write-Host ""
            $configuredConn = $panzuraConns | Where-Object { $_.id -eq $env:NEXUS_AI_CONNECTOR_ID }
            $otherConns     = $panzuraConns | Where-Object { $_.id -ne $env:NEXUS_AI_CONNECTOR_ID }
            Write-Host "  Graph external connections (panzura/nexus):" -ForegroundColor Cyan
            if ($configuredConn) {
                Write-Host "    $($configuredConn.name)  id: $($configuredConn.id)  state: $($configuredConn.state)  (configured)" -ForegroundColor Green
            }
            if ($otherConns) {
                Write-Info "  $($otherConns.Count) other panzura/nexus Graph connections in tenant (details in JSON)"
            }
            $inv.m365.allGraphConnectors = @($panzuraConns | ForEach-Object {
                [ordered]@{ name = $_.name; id = $_.id; state = $_.state; configured = ($_.id -eq $env:NEXUS_AI_CONNECTOR_ID) }
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

$otherCount = 0
$otherCount += @($inv.broadSearch.entraApps              | Where-Object { -not $_.configured -and -not $_.knownSafe }).Count
$otherCount += @($inv.broadSearch.entraServicePrincipals | Where-Object { -not $_.configured -and -not $_.knownSafe }).Count
$otherCount += @($inv.m365.allGraphConnectors            | Where-Object { -not $_.configured }).Count

if ($otherCount -gt 0) {
    Write-Host "$otherCount other panzura/nexus resource(s) in this environment (not ours) — see [XTRA] items above." -ForegroundColor DarkGray
}
