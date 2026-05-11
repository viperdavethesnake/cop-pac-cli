<#
.SYNOPSIS
    Register the Nexus application in Microsoft Entra ID.
    Outputs Tenant ID and Client ID — update .env with these values.

.NOTES
    Admin Guide: §2.10.2
    Run as: Global Administrator or Application Administrator
    After this script: run 02-Set-ApiPermissions.ps1, then 03-New-ClientSecret.ps1

    Authentication: interactive browser login (delegated admin required for app registration).
    MSAL caches the token after first login — 02 and 03 will reuse it silently, no extra popups.
#>

$script:RequiredVars = @('ENTRA_TENANT_ID', 'ENTRA_APP_NAME')
. "$PSScriptRoot/../_common/Config.ps1"

$appDisplayName = $env:ENTRA_APP_NAME

# ── Auth (interactive for first-time registration) ────────────────────────────
# TODO: Determine whether to use interactive or service-principal auth here.
# First-run bootstrap requires interactive login (no app exists yet).
Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "Application.ReadWrite.All" -NoWelcome

# ── Register App ──────────────────────────────────────────────────────────────
# TODO: Check if app already exists before creating
$existingApp = Get-MgApplication -Filter "displayName eq '$appDisplayName'" -ErrorAction SilentlyContinue

if ($existingApp) {
    Write-Host "App already registered: $($existingApp.DisplayName) (AppId: $($existingApp.AppId))" -ForegroundColor Yellow
    $app = $existingApp
} else {
    $app = New-MgApplication -DisplayName $appDisplayName `
        -SignInAudience "AzureADMyOrg"

    Write-Host "App registered: $($app.DisplayName)" -ForegroundColor Green
    Write-Host "  AppId (Client ID): $($app.AppId)"
}

# ── Output ────────────────────────────────────────────────────────────────────
$context  = Get-MgContext
$tenantId = $context.TenantId

Set-EnvValue 'ENTRA_CLIENT_ID' $app.AppId

Write-Host ""
Write-Host "Tenant ID : $tenantId"
Write-Host "Client ID : $($app.AppId)"
Write-Host "Object ID : $($app.Id)  (internal — used by other entra scripts)"
Write-Host ""
Write-Host "ENTRA_CLIENT_ID written to .env." -ForegroundColor Green
Write-Host "Run next: scripts/entra/02-Set-ApiPermissions.ps1" -ForegroundColor Cyan

# Store app object ID in env for downstream scripts (session only)
$env:ENTRA_APP_OBJECT_ID = $app.Id
