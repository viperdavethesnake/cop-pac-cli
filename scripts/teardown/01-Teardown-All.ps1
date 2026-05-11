<#
.SYNOPSIS
    Reverse all confirmed deployment steps in order:
      1. Delete Power Apps custom connector
      2. Remove Power Platform redirect URI from Entra app
      3. Delete Entra app registration (cascades: secrets, permissions, service principal)
      4. Purge soft-deleted app from Entra (skips 30-day recycle bin)
      5. Clear auto-written keys from .env

.NOTES
    Run as: Global Administrator
    Reads connector ID and app details from .env — make sure .env reflects
    the current deployment before running.

    Safe to run partially — each step checks whether the resource exists
    before attempting deletion and reports SKIP if already gone.
#>

$script:RequiredVars = @('ENTRA_TENANT_ID', 'ENTRA_APP_NAME')
. "$PSScriptRoot/../_common/Config.ps1"

# ── Confirmation prompt ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "Nexus Teardown" -ForegroundColor Red
Write-Host ("─" * 60)
Write-Host ""
Write-Host "This will permanently delete:" -ForegroundColor Yellow
Write-Host "  - Power Apps connector: $($env:CONNECTOR_NAME) (ID: $($env:PPAC_ENVIRONMENT_URL ? '20bdb32b-...' : 'unknown'))"
Write-Host "  - Entra app registration: $($env:ENTRA_APP_NAME) (AppId: $($env:ENTRA_CLIENT_ID))"
Write-Host "  - All client secrets and API permissions for that app"
Write-Host "  - Auto-written .env values: ENTRA_CLIENT_ID, ENTRA_CLIENT_SECRET, PPAC_ENVIRONMENT_URL"
Write-Host ""
$confirm = Read-Host "Type 'yes' to proceed"
if ($confirm -ne 'yes') {
    Write-Host "Aborted." -ForegroundColor DarkGray
    exit 0
}

$errors = @()

function Write-Step { param([string]$msg) Write-Host ""; Write-Host $msg -ForegroundColor Cyan }
function Write-Ok   { param([string]$msg) Write-Host "  [DONE] $msg" -ForegroundColor Green }
function Write-Skip { param([string]$msg) Write-Host "  [SKIP] $msg" -ForegroundColor DarkGray }
function Write-Fail { param([string]$msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:errors += $msg }

# ── Step 1: Delete Power Apps custom connector ────────────────────────────────
Write-Step "Step 1 — Delete Power Apps custom connector"

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Fail "PAC CLI not found — skipping connector deletion"
} elseif (-not $env:PPAC_ENVIRONMENT_URL) {
    Write-Skip "PPAC_ENVIRONMENT_URL not set — connector may not have been created"
} else {
    try {
        $connectorList = pac connector list --environment $env:PPAC_ENVIRONMENT_URL 2>&1
        $guidRegex     = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'

        # Match by CONNECTOR_NAME first, then fall back to any panzura/nexus line
        $connectorLine = $connectorList | Where-Object { $_ -match [regex]::Escape($env:CONNECTOR_NAME) } | Select-Object -First 1
        if (-not $connectorLine) {
            $connectorLine = $connectorList | Where-Object { $_ -match 'panzura|nexus' -and $_ -match $guidRegex } | Select-Object -First 1
        }

        if (-not $connectorLine) {
            Write-Skip "No panzura/nexus connector found in environment"
        } else {
            $connectorId   = ([regex]$guidRegex).Match($connectorLine).Value
            $connectorName = ($connectorLine.Trim() -split '\s+')[0]
            if (-not $connectorId) {
                Write-Fail "Could not parse connector ID from pac output"
            } else {
                Write-Host "  Deleting connector '$connectorName' ($connectorId) via PowerApps admin module..." -ForegroundColor DarkGray
                try {
                    # pac connector delete and pac api execute do not exist in PAC CLI 2.7.x
                    # Use Microsoft.PowerApps.Administration.PowerShell instead
                    Add-PowerAppsAccount -TenantID $env:ENTRA_TENANT_ID -Endpoint prod | Out-Null
                    $orgName   = ([uri]$env:PPAC_ENVIRONMENT_URL).Host.Split('.')[0]
                    $targetEnv = Get-AdminEnvironment | Where-Object {
                        $_.Internal.properties.linkedEnvironmentMetadata.instanceUrl -match $orgName
                    } | Select-Object -First 1
                    if (-not $targetEnv) {
                        Write-Fail "Could not find environment matching $($env:PPAC_ENVIRONMENT_URL) — delete connector manually at make.powerapps.com > Custom connectors"
                    } else {
                        $envName = $targetEnv.EnvironmentName
                        Remove-AdminConnector -ConnectorName $connectorName -EnvironmentName $envName -ErrorAction Stop
                        Write-Ok "Connector deleted (ID: $connectorId)"
                    }
                } catch {
                    Write-Fail "Connector deletion failed: $($_.Exception.Message) — delete manually at make.powerapps.com > Custom connectors"
                }
            }
        }
    } catch {
        Write-Fail "Connector deletion error: $($_.Exception.Message)"
    }
}

# ── Step 2 & 3: Graph operations ──────────────────────────────────────────────
Write-Step "Connecting to Microsoft Graph..."
try {
    Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "Application.ReadWrite.All","Directory.ReadWrite.All" -NoWelcome -ErrorAction Stop
    Write-Host "  Connected." -ForegroundColor DarkGray
} catch {
    Write-Fail "Could not connect to Graph: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Cannot continue without Graph connection. Fix the error above and re-run." -ForegroundColor Red
    exit 1
}

# Find the app
$app = $null
if ($env:ENTRA_CLIENT_ID) {
    $app = Get-MgApplication -Filter "appId eq '$($env:ENTRA_CLIENT_ID)'" -ErrorAction SilentlyContinue
}
if (-not $app) {
    $app = Get-MgApplication -Filter "displayName eq '$($env:ENTRA_APP_NAME)'" -ErrorAction SilentlyContinue | Select-Object -First 1
}

# ── Step 2: Remove redirect URI ───────────────────────────────────────────────
Write-Step "Step 2 — Remove Power Platform redirect URI from Entra app"

$ppRedirectUri = "https://global.consent.azure-apim.net/redirect"

if (-not $app) {
    Write-Skip "App '$($env:ENTRA_APP_NAME)' not found — already deleted or never created"
} else {
    $existingUris = @($app.Web.RedirectUris)
    if ($ppRedirectUri -notin $existingUris) {
        Write-Skip "Redirect URI not present"
    } else {
        try {
            $updatedUris = $existingUris | Where-Object { $_ -ne $ppRedirectUri }
            Update-MgApplication -ApplicationId $app.Id -Web @{ RedirectUris = [string[]]$updatedUris } -ErrorAction Stop
            Write-Ok "Removed: $ppRedirectUri"
        } catch {
            Write-Fail "Could not remove redirect URI: $($_.Exception.Message)"
        }
    }
}

# ── Step 3: Delete Entra app registration ────────────────────────────────────
Write-Step "Step 3 — Delete Entra app registration '$($env:ENTRA_APP_NAME)'"

if (-not $app) {
    Write-Skip "App not found — already deleted"
} else {
    try {
        $appId  = $app.Id
        $appDisplayName = $app.DisplayName
        Remove-MgApplication -ApplicationId $appId -ErrorAction Stop
        Write-Ok "Deleted app '$appDisplayName' (object ID: $appId)"
        Write-Host "  Note: also deletes all client secrets, API permissions, and service principal" -ForegroundColor DarkGray
    } catch {
        Write-Fail "Could not delete app: $($_.Exception.Message)"
    }
}

# ── Step 4: Purge from soft-delete recycle bin ────────────────────────────────
Write-Step "Step 4 — Purge app from Entra soft-delete (skips 30-day hold)"

try {
    # Soft-deleted apps appear as microsoft.graph.application in the deleted items list
    $deletedApps = Get-MgDirectoryDeletedItem -DirectoryObjectId " " -ErrorAction SilentlyContinue 2>$null
    # Query by app name
    $deletedApp = Get-MgDirectoryDeletedItemAsApplication -Filter "displayName eq '$($env:ENTRA_APP_NAME)'" -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $deletedApp) {
        # May take a few seconds to appear — try once more
        Start-Sleep -Seconds 5
        $deletedApp = Get-MgDirectoryDeletedItemAsApplication -Filter "displayName eq '$($env:ENTRA_APP_NAME)'" -ErrorAction SilentlyContinue |
            Select-Object -First 1
    }

    if ($deletedApp) {
        Remove-MgDirectoryDeletedItem -DirectoryObjectId $deletedApp.Id -ErrorAction Stop
        Write-Ok "Purged '$($env:ENTRA_APP_NAME)' from soft-delete recycle bin"
    } else {
        Write-Skip "App not found in soft-delete bin (may take a moment — safe to ignore)"
    }
} catch {
    Write-Fail "Could not purge soft-deleted app: $($_.Exception.Message)"
}

# ── Step 5: Clear auto-written .env keys ─────────────────────────────────────
Write-Step "Step 5 — Clear auto-written .env keys"

$keysToClear = @(
    'ENTRA_CLIENT_ID'
    'ENTRA_CLIENT_SECRET'
    'ENTRA_APP_OBJECT_ID'
    'PPAC_ENVIRONMENT_URL'
    'NEXUS_STORAGE_PLUGIN_ID'
    'NEXUS_AI_PLUGIN_ID'
    'NEXUS_IAM_PLUGIN_ID'
    'NEXUS_POLICY_ID'
    'NEXUS_AI_CONNECTOR_ID'
)

foreach ($key in $keysToClear) {
    Set-EnvValue $key ''
}
Write-Ok "Cleared: $($keysToClear -join ', ')"

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ("─" * 60)
if ($errors.Count -eq 0) {
    Write-Host "Teardown complete — all resources removed." -ForegroundColor Green
} else {
    Write-Host "Teardown completed with $($errors.Count) error(s):" -ForegroundColor Yellow
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Re-run after fixing the errors above, or clean up manually in portal.azure.com / make.powerapps.com" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "To redeploy from scratch, fill .env Stage 1 keys and run:" -ForegroundColor DarkGray
Write-Host "  scripts/entra/00-Validate-Prerequisites.ps1" -ForegroundColor DarkGray
