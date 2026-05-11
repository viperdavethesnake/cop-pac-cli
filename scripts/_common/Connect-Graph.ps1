<#
.SYNOPSIS
    Authenticate to Microsoft Graph using client credentials from .env.
    Source this before calling any Microsoft.Graph cmdlets.

.NOTES
    Requires: Install-Module Microsoft.Graph -Scope CurrentUser
    Scopes needed for Nexus: Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All,
                              DelegatedPermissionGrant.ReadWrite.All
#>

. "$PSScriptRoot/Config.ps1"

$tenantId     = $env:ENTRA_TENANT_ID
$clientId     = $env:ENTRA_CLIENT_ID
$clientSecret = $env:ENTRA_CLIENT_SECRET

if (-not $tenantId -or -not $clientId -or -not $clientSecret) {
    throw "ENTRA_TENANT_ID, ENTRA_CLIENT_ID, and ENTRA_CLIENT_SECRET must be set in .env"
}

$secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($clientId, $secureSecret)

Connect-MgGraph `
    -TenantId   $tenantId `
    -ClientSecretCredential $credential `
    -NoWelcome

Write-Host "Connected to Microsoft Graph (tenant: $tenantId)" -ForegroundColor Green
