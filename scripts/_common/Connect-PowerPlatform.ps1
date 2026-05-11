<#
.SYNOPSIS
    Authenticate to Power Platform Admin Center.
    Source this before calling Microsoft.PowerApps.Administration.PowerShell cmdlets.

.NOTES
    Requires:
        Install-Module Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser
        Install-Module Microsoft.PowerApps.PowerShell -Scope CurrentUser

    Uses interactive login — a browser window will open.
    Service-principal auth for PPAC is limited; interactive is most reliable.
#>

. "$PSScriptRoot/Config.ps1"

# Interactive login — opens browser
Add-PowerAppsAccount

$envUrl  = $env:PPAC_ENVIRONMENT_URL
$envName = $env:PPAC_ENVIRONMENT_NAME

if ($envUrl) {
    Write-Host "Power Platform connected. Target environment: $envName ($envUrl)" -ForegroundColor Green
} else {
    Write-Warning "PPAC_ENVIRONMENT_URL not set in .env — set it before running power-platform scripts."
}
