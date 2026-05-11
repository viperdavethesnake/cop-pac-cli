<#
.SYNOPSIS
    Configure the Active Directory IAM Plugin in Nexus via REST API.

.NOTES
    Admin Guide: §2.8.3
    This links on-prem AD to Nexus for user identity mapping.
    Entra Connect V2 must already be syncing AD → Entra ID.
#>

$script:RequiredVars = @('NEXUS_IP', 'NEXUS_ADMIN_USER', 'NEXUS_ADMIN_PASSWORD',
                        'AD_HOST', 'AD_DOMAIN', 'AD_BIND_USER', 'AD_BIND_PASSWORD')
. "$PSScriptRoot/../_common/Config.ps1"

$nexusBase = "https://$($env:NEXUS_IP)"

# ── Auth ──────────────────────────────────────────────────────────────────────
$loginBody = @{ username = $env:NEXUS_ADMIN_USER; password = $env:NEXUS_ADMIN_PASSWORD } | ConvertTo-Json
$session   = Invoke-RestMethod -Uri "$nexusBase/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$headers   = @{ Authorization = "Bearer $($session.token)" }

# ── Configure IAM Plugin ──────────────────────────────────────────────────────
$pluginBody = @{
    name           = "ad-primary"
    description    = "On-premises Active Directory"
    adDomainName   = $env:AD_DOMAIN
    adUser         = $env:AD_BIND_USER
    adUserPassword = $env:AD_BIND_PASSWORD
    adHost         = $env:AD_HOST
    # TODO: Add connection type (LDAP/LDAPS/LDAP+TLS) and port once endpoint schema confirmed
} | ConvertTo-Json

# TODO: Confirm endpoint path
$result = Invoke-RestMethod -Uri "$nexusBase/api/plugins/iam" `
    -Method Post -Body $pluginBody -ContentType "application/json" -Headers $headers

Write-Host "IAM plugin configured." -ForegroundColor Green

Set-EnvValue 'NEXUS_IAM_PLUGIN_ID' $result.id
Write-Host "IAM Plugin ID: $($result.id)" -ForegroundColor Cyan
Write-Host "Run next: scripts/nexus/04-Configure-Rules.ps1" -ForegroundColor Cyan
