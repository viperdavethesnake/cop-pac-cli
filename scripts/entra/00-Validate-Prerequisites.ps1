<#
.SYNOPSIS
    Pre-flight validation. Run this FIRST before any other script.
    Checks every cloud-side prerequisite and reports pass/fail with fix instructions.

.CHECKS
    1. Microsoft Graph connectivity (tenant reachable, credentials valid)
    2. M365 Copilot licenses — at least one SKU assigned in tenant
    3. Entra hybrid sync — on-prem AD users are syncing to Entra (Entra Connect V2)
    4. Nexus Entra app — does not already exist (idempotency guard)
    5. Required PowerShell modules installed
    6. PAC CLI installed
    7. .env completeness — all required keys have values

.NOTES
    Run as: Global Administrator
    Fix any FAIL items before running entra/01 through copilot/03.
#>

$script:RequiredVars = @('ENTRA_TENANT_ID', 'ENTRA_APP_NAME')
. "$PSScriptRoot/../_common/Config.ps1"

$pass  = 0
$fail  = 0
$warn  = 0
$items = @()

function Add-Result {
    param([string]$Check, [string]$Status, [string]$Detail, [string]$Fix = "")
    $script:items += [PSCustomObject]@{
        Check  = $Check
        Status = $Status
        Detail = $Detail
        Fix    = $Fix
    }
    if ($Status -eq "PASS")  { $script:pass++ }
    if ($Status -eq "FAIL")  { $script:fail++ }
    if ($Status -eq "WARN")  { $script:warn++ }
}

Write-Host ""
Write-Host "Nexus Pre-flight Validation" -ForegroundColor Cyan
Write-Host ("─" * 60)

# ── 1. Required PS modules ────────────────────────────────────────────────────
$requiredModules = @(
    "Microsoft.Graph"
    "Microsoft.PowerApps.Administration.PowerShell"
    "Posh-SSH"
)
foreach ($mod in $requiredModules) {
    if (Get-Module -ListAvailable $mod -ErrorAction SilentlyContinue) {
        Add-Result "Module: $mod" "PASS" "Installed"
    } else {
        Add-Result "Module: $mod" "FAIL" "Not installed" `
            "Install-Module $mod -Scope CurrentUser"
    }
}

# ── 2. PAC CLI ────────────────────────────────────────────────────────────────
if (Get-Command pac -ErrorAction SilentlyContinue) {
    $pacVer = (pac --version 2>&1) | Select-Object -First 1
    Add-Result "PAC CLI" "PASS" $pacVer
} else {
    Add-Result "PAC CLI" "WARN" "Not found — required for copilot/01, not needed for entra/ scripts" `
        "npm install -g @microsoft/powerplatform-cli"
}

# ── 3. .env completeness ──────────────────────────────────────────────────────
# Stage 1 keys must exist before running any entra/ script.
$stage1Required = @("ENTRA_APP_NAME", "CONNECTOR_NAME", "ENTRA_TENANT_ID")

# Written automatically by entra/01 and entra/03 — expected blank on first run.
$stage1AutoWritten = @("ENTRA_CLIENT_ID", "ENTRA_CLIENT_SECRET")

# Blocked on infrastructure — warn, don't fail.
$infrastructureKeys = @(
    "NEXUS_IP", "NEXUS_ADMIN_USER", "NEXUS_ADMIN_PASSWORD",
    "CLOUDFS_MASTER_NODE", "CLOUDFS_ADMIN_USER", "CLOUDFS_SMB_NODE",
    "CLOUDFS_SMB_USER", "CLOUDFS_DOMAIN",
    "AD_HOST", "AD_DOMAIN", "AD_BIND_USER", "AD_BIND_PASSWORD"
)

$missingStage1 = $stage1Required | Where-Object { -not (Get-Item "env:$_" -ErrorAction SilentlyContinue)?.Value }
$missingAutoWritten = $stage1AutoWritten | Where-Object { -not (Get-Item "env:$_" -ErrorAction SilentlyContinue)?.Value }
$missingInfra = $infrastructureKeys | Where-Object { -not (Get-Item "env:$_" -ErrorAction SilentlyContinue)?.Value }

if ($missingStage1) {
    Add-Result ".env Stage 1 keys" "FAIL" "Missing: $($missingStage1 -join ', ')" `
        "Fill in these values in .env before proceeding"
} else {
    Add-Result ".env Stage 1 keys" "PASS" "ENTRA_APP_NAME, CONNECTOR_NAME, ENTRA_TENANT_ID all set"
}
if ($missingAutoWritten) {
    Add-Result ".env auto-written keys" "WARN" "Not yet set: $($missingAutoWritten -join ', ')" `
        "Written automatically by entra/01 and entra/03 — OK to be blank before those scripts run"
}
if ($missingInfra) {
    Add-Result ".env infrastructure keys" "WARN" "Not yet set: $($missingInfra -join ', ')" `
        "Fill in when Nexus VM, CloudFS, and AD are deployed — OK to be blank now"
}

# ── 4. Microsoft Graph connectivity ──────────────────────────────────────────
try {
    Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID `
        -ClientSecretCredential (
            New-Object System.Management.Automation.PSCredential(
                $env:ENTRA_CLIENT_ID,
                (ConvertTo-SecureString $env:ENTRA_CLIENT_SECRET -AsPlainText -Force)
            )
        ) -NoWelcome -ErrorAction Stop
    $ctx = Get-MgContext
    Add-Result "Graph connectivity" "PASS" "Connected — tenant: $($ctx.TenantId)"
} catch {
    # Fall back to interactive if service principal auth fails (first-run before app exists)
    try {
        Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "User.Read","Directory.Read.All","User.Read.All" -NoWelcome -ErrorAction Stop
        Add-Result "Graph connectivity" "PASS" "Connected via interactive login (app not registered yet)"
    } catch {
        Add-Result "Graph connectivity" "FAIL" $_.Exception.Message `
            "Check ENTRA_TENANT_ID in .env and network connectivity"
    }
}

# ── 5. M365 Copilot licensing ─────────────────────────────────────────────────
# Copilot SKU part numbers to look for
$copilotSkus = @(
    "Microsoft_Copilot"          # Microsoft Copilot
    "Copilot_for_Microsoft_365"  # M365 Copilot add-on
    "MICROSOFT_365_COPILOT"
)
try {
    $subscribedSkus = Get-MgSubscribedSku -ErrorAction Stop
    $copilotLicenses = $subscribedSkus | Where-Object {
        $sku = $_.SkuPartNumber
        $copilotSkus | Where-Object { $sku -like "*$_*" -or $sku -like "*copilot*" }
    }
    if ($copilotLicenses) {
        $summary = ($copilotLicenses | ForEach-Object {
            "$($_.SkuPartNumber): $($_.PrepaidUnits.Enabled - $_.ConsumedUnits) available of $($_.PrepaidUnits.Enabled)"
        }) -join "; "
        Add-Result "M365 Copilot licenses" "PASS" $summary
    } else {
        Add-Result "M365 Copilot licenses" "FAIL" "No Copilot SKU found in tenant" `
            "Purchase M365 Copilot licenses and assign to users before proceeding"
    }
} catch {
    Add-Result "M365 Copilot licenses" "WARN" "Could not query licenses: $($_.Exception.Message)" `
        "Verify manually: admin.microsoft.com > Billing > Licenses"
}

# ── 6. Entra hybrid sync (Entra Connect V2) ───────────────────────────────────
try {
    # Check if any users have onPremisesSyncEnabled = true
    $syncedUsers = Get-MgUser -Filter "onPremisesSyncEnabled eq true" -Top 5 -ErrorAction Stop
    if ($syncedUsers) {
        $countVar = $null
        Get-MgUser -Filter "onPremisesSyncEnabled eq true" -CountVariable countVar -ConsistencyLevel eventual -Top 1 -ErrorAction SilentlyContinue | Out-Null
        $totalSynced = if ($countVar) { $countVar } else { "$($syncedUsers.Count)+" }
        Add-Result "Entra hybrid sync" "PASS" "$totalSynced users synced from on-prem AD"
    } else {
        Add-Result "Entra hybrid sync" "FAIL" "No synced users found — onPremisesSyncEnabled is not true for any user" `
            "Install and configure Microsoft Entra Connect V2 on-prem. See docs/ms-reference/entra-connect-v2-overview.md"
    }
} catch {
    Add-Result "Entra hybrid sync" "WARN" "Could not query user sync status: $($_.Exception.Message)" `
        "Verify manually: entra.microsoft.com > Users > check onPremisesSyncEnabled"
}

# ── 7. Nexus app — idempotency guard ─────────────────────────────────────────
try {
    $existingApp = Get-MgApplication -Filter "displayName eq '$($env:ENTRA_APP_NAME)'" -ErrorAction Stop
    if ($existingApp) {
        Add-Result "Nexus Entra app" "WARN" "App '$($env:ENTRA_APP_NAME)' already exists (AppId: $($existingApp.AppId))" `
            "entra/01 will reuse existing app — not create a duplicate"
    } else {
        Add-Result "Nexus Entra app" "PASS" "No existing '$($env:ENTRA_APP_NAME)' app — safe to register"
    }
} catch {
    Add-Result "Nexus Entra app" "WARN" "Could not check for existing app — will be verified in entra/01"
}

# ── 8. Nexus host reachability ────────────────────────────────────────────────
if ($env:NEXUS_IP) {
    try {
        $response = Invoke-WebRequest -Uri "https://$($env:NEXUS_IP)" `
            -TimeoutSec 5 -SkipCertificateCheck -ErrorAction Stop
        Add-Result "Nexus host reachable" "PASS" "HTTPS 443 open at $($env:NEXUS_IP)"
    } catch {
        if ($_.Exception.Message -match "SSL|certificate|TLS") {
            Add-Result "Nexus host reachable" "WARN" "Reachable but SSL error (expected for self-signed cert)" `
                "Set NEXUS_SKIP_SSL_VERIFY=true in .env for lab use"
        } else {
            Add-Result "Nexus host reachable" "FAIL" "Cannot reach $($env:NEXUS_IP):443 — $($_.Exception.Message)" `
                "Ensure Nexus VM is running and port 443 is open in firewall/NSG"
        }
    }
} else {
    Add-Result "Nexus host reachable" "WARN" "NEXUS_IP not set — skipping reachability check"
}

# ── Print results ─────────────────────────────────────────────────────────────
Write-Host ""
$items | ForEach-Object {
    $color = switch ($_.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
    }
    $icon = switch ($_.Status) {
        "PASS" { "[PASS]" }
        "FAIL" { "[FAIL]" }
        "WARN" { "[WARN]" }
    }
    Write-Host "$icon  $($_.Check)" -ForegroundColor $color
    Write-Host "       $($_.Detail)" -ForegroundColor DarkGray
    if ($_.Fix -and $_.Status -ne "PASS") {
        Write-Host "       Fix: $($_.Fix)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host ("─" * 60)
Write-Host "Results: $pass PASS  |  $warn WARN  |  $fail FAIL" -ForegroundColor $(if ($fail -gt 0) { "Red" } elseif ($warn -gt 0) { "Yellow" } else { "Green" })

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "Fix all FAIL items before running any other scripts." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "Ready to proceed. Run scripts in order:" -ForegroundColor Green
    Write-Host "  1. scripts/cloudfs/01-Enable-AuditSettings.ps1  (manual UI steps)"
    Write-Host "  2. scripts/entra/01-Register-NexusApp.ps1"
    Write-Host "  3. scripts/entra/02-Set-ApiPermissions.ps1"
    Write-Host "  4. scripts/entra/03-New-ClientSecret.ps1"
    Write-Host "  5. scripts/nexus/ (01 through 06)"
    Write-Host "  6. scripts/m365/01-Enable-ConnectorForCopilot.ps1"
    Write-Host "  7. scripts/copilot/ (01 through 03)"
}
