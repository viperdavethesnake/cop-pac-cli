<#
.SYNOPSIS
    Assign the System Administrator security role to the Nexus app user
    in the Power Platform default environment.

.NOTES
    Admin Guide: §2.10.5 — "Security roles: System Administrator"
    SCOPE NOTE: Only required for Path B (Nexus web UI wizard for agent creation).
    We are using Path A (manual Copilot Studio workflow) — skip this unless
    switching to Path B later.

    Must run AFTER 01-Register-ServicePrincipal.ps1
#>

. "$PSScriptRoot/../_common/Config.ps1"
. "$PSScriptRoot/../_common/Connect-PowerPlatform.ps1"

$clientId = $env:ENTRA_CLIENT_ID
$envUrl   = $env:PPAC_ENVIRONMENT_URL

if (-not $clientId) { throw "ENTRA_CLIENT_ID not set in .env" }
if (-not $envUrl)   { throw "PPAC_ENVIRONMENT_URL not set in .env" }

# ── Assign System Administrator role ─────────────────────────────────────────
# TODO: Implement role assignment
# The app user created in step 01 needs "System Administrator" security role
# This is done via Dataverse API or Microsoft.PowerApps.Administration.PowerShell

Write-Host "TODO: Role assignment not yet implemented" -ForegroundColor Yellow
Write-Host ""
Write-Host "Manual equivalent:"
Write-Host "  1. PPAC > Environments > $envUrl > Settings > Users"
Write-Host "  2. Find the app user (Client ID: $clientId)"
Write-Host "  3. Security Roles > System Administrator"

# ── Verify ────────────────────────────────────────────────────────────────────
# TODO: Add verification step — confirm role appears in Direct Assigned Roles
# Admin Guide §2.10.5 "Verify System Administrator Role Assignment"
Write-Host ""
Write-Host "Verification steps (manual):"
Write-Host "  1. PPAC > Manage > select Default environment"
Write-Host "  2. Users > find your username > Direct Assigned Roles"
Write-Host "  3. Confirm 'System Administrator' is listed"
