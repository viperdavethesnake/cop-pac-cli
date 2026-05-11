<#
.SYNOPSIS
    Register the Nexus Entra app as an application user in the Power Platform
    default environment.

.NOTES
    Admin Guide: §2.10.5
    SCOPE NOTE: This is only required if using Path B (Nexus web UI wizard for agent
    creation). We are using Path A (manual Copilot Studio workflow) so these scripts
    are LOW PRIORITY and can be skipped unless agent creation via Nexus UI is needed later.

    Run as: System Administrator in Power Platform (not just any admin)
    Requires interactive login — opens browser for PPAC auth.
#>

. "$PSScriptRoot/../_common/Config.ps1"
. "$PSScriptRoot/../_common/Connect-PowerPlatform.ps1"

$clientId = $env:ENTRA_CLIENT_ID
$envName  = $env:PPAC_ENVIRONMENT_NAME

if (-not $clientId) { throw "ENTRA_CLIENT_ID not set in .env" }
if (-not $envName)  { throw "PPAC_ENVIRONMENT_NAME not set in .env" }

# ── Add app user to environment ───────────────────────────────────────────────
# TODO: Resolve exact cmdlet — New-PowerAppManagementApp or direct API call
# The Entra app (by ClientId) must be added as an app user in the default environment
# before security roles can be assigned.

Write-Host "Registering app (Client ID: $clientId) in environment: $envName" -ForegroundColor Cyan

# TODO: Implement with New-PowerAppManagementApp or Invoke-RestMethod against PPAC API
# Reference: https://learn.microsoft.com/en-us/power-platform/admin/manage-application-users

Write-Host "TODO: Service principal registration not yet implemented" -ForegroundColor Yellow
Write-Host "Manual equivalent:"
Write-Host "  1. Login to Power Platform Admin Center"
Write-Host "  2. Environments > $envName > Settings > Users"
Write-Host "  3. + New app user > Add app (search by Client ID: $clientId)"
