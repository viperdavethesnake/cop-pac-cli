<#
.SYNOPSIS
    Configure the CloudFS Storage Plugin in Nexus via REST API.
    Optionally installs the license key first.

.NOTES
    Admin Guide: §2.8.1, §2.10.1 (License Management)
    Nexus must be running and reachable on port 443.
    Exact REST endpoints must be confirmed via browser DevTools on a live Nexus instance.
#>

$script:RequiredVars = @('NEXUS_IP', 'NEXUS_ADMIN_USER', 'NEXUS_ADMIN_PASSWORD',
                        'CLOUDFS_MASTER_NODE', 'CLOUDFS_ADMIN_USER', 'CLOUDFS_ADMIN_PASSWORD',
                        'CLOUDFS_SMB_NODE', 'CLOUDFS_SMB_USER', 'CLOUDFS_SMB_PASSWORD', 'CLOUDFS_DOMAIN')
. "$PSScriptRoot/../_common/Config.ps1"

$nexusBase  = "https://$($env:NEXUS_IP)"
$adminUser  = $env:NEXUS_ADMIN_USER
$adminPass  = $env:NEXUS_ADMIN_PASSWORD

if (-not $env:NEXUS_IP) { throw "NEXUS_IP not set in .env" }

# ── Auth — get session token ──────────────────────────────────────────────────
# TODO: Discover actual auth endpoint from live Nexus (likely POST /api/auth/login)
$loginBody = @{ username = $adminUser; password = $adminPass } | ConvertTo-Json
$session = Invoke-RestMethod -Uri "$nexusBase/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"
$headers = @{ Authorization = "Bearer $($session.token)" }

# ── (Optional) Install License ────────────────────────────────────────────────
if ($env:NEXUS_LICENSE_KEY) {
    # TODO: Confirm license endpoint
    $licenseBody = @{ key = $env:NEXUS_LICENSE_KEY } | ConvertTo-Json
    Invoke-RestMethod -Uri "$nexusBase/api/license" `
        -Method Post -Body $licenseBody -ContentType "application/json" -Headers $headers
    Write-Host "License installed." -ForegroundColor Green
}

# ── Configure Storage Plugin (CloudFS) ───────────────────────────────────────
$pluginBody = @{
    name          = "cloudfs-primary"
    description   = "Primary CloudFS ring"
    masterNode    = $env:CLOUDFS_MASTER_NODE
    adminUser     = $env:CLOUDFS_ADMIN_USER
    adminPassword = $env:CLOUDFS_ADMIN_PASSWORD
    smbNode       = $env:CLOUDFS_SMB_NODE
    smbUser       = $env:CLOUDFS_SMB_USER
    smbPassword   = $env:CLOUDFS_SMB_PASSWORD
    domain        = $env:CLOUDFS_DOMAIN
    smbConnections = 4   # TODO: confirm default / make configurable
} | ConvertTo-Json

# TODO: Confirm endpoint path — likely POST /api/plugins/storage
$result = Invoke-RestMethod -Uri "$nexusBase/api/plugins/storage" `
    -Method Post -Body $pluginBody -ContentType "application/json" -Headers $headers

Write-Host "Storage plugin configured." -ForegroundColor Green

Set-EnvValue 'NEXUS_STORAGE_PLUGIN_ID' $result.id
Write-Host "Storage Plugin ID: $($result.id)" -ForegroundColor Cyan
Write-Host "Run next: scripts/nexus/02-Configure-AiPlugin.ps1" -ForegroundColor Cyan
