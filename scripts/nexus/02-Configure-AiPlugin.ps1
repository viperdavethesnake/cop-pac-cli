<#
.SYNOPSIS
    Configure the Microsoft Copilot AI Plugin in Nexus via REST API.

.NOTES
    Admin Guide: §2.8.2
    Requires: Tenant ID, Client ID, Client Secret from Entra app registration.
    These are already in .env after running scripts/entra/
#>

$script:RequiredVars = @('NEXUS_IP', 'NEXUS_ADMIN_USER', 'NEXUS_ADMIN_PASSWORD',
                        'ENTRA_TENANT_ID', 'ENTRA_CLIENT_ID', 'ENTRA_CLIENT_SECRET')
. "$PSScriptRoot/../_common/Config.ps1"

$nexusBase = "https://$($env:NEXUS_IP)"

# ── Auth ──────────────────────────────────────────────────────────────────────
# TODO: Refactor auth to a helper function in _common
$loginBody = @{ username = $env:NEXUS_ADMIN_USER; password = $env:NEXUS_ADMIN_PASSWORD } | ConvertTo-Json
$session   = Invoke-RestMethod -Uri "$nexusBase/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$headers   = @{ Authorization = "Bearer $($session.token)" }

# ── Configure AI Plugin ───────────────────────────────────────────────────────
$pluginBody = @{
    name         = "copilot-primary"
    description  = "Microsoft 365 Copilot integration"
    tenantId     = $env:ENTRA_TENANT_ID
    clientId     = $env:ENTRA_CLIENT_ID
    clientSecret = $env:ENTRA_CLIENT_SECRET
} | ConvertTo-Json

# TODO: Confirm endpoint path — likely POST /api/plugins/ai
$result = Invoke-RestMethod -Uri "$nexusBase/api/plugins/ai" `
    -Method Post -Body $pluginBody -ContentType "application/json" -Headers $headers

Write-Host "AI plugin configured." -ForegroundColor Green

Set-EnvValue 'NEXUS_AI_PLUGIN_ID' $result.id
Write-Host "AI Plugin ID: $($result.id)" -ForegroundColor Cyan
Write-Host "Run next: scripts/nexus/03-Configure-IamPlugin.ps1" -ForegroundColor Cyan
