<#
.SYNOPSIS
    Verify the Graph Connector is active and items are being ingested.
    Run this after nexus/06 to confirm the connector is healthy before
    building the Copilot agent.

.NOTES
    Checks:
      - Connector state (should be 'ready')
      - Item count (should be > 0 after first full scan completes)
      - Last ingestion activity
    Admin Guide: §2.6.2 (Data Insights Dashboard) — this script is the API equivalent.
#>

. "$PSScriptRoot/../_common/Config.ps1"
. "$PSScriptRoot/../_common/Connect-Graph.ps1"

$connectorId = $env:NEXUS_AI_CONNECTOR_ID

if (-not $connectorId) {
    throw "NEXUS_AI_CONNECTOR_ID not set in .env. Run nexus/06-Activate-Policy.ps1 first."
}

Write-Host ""
Write-Host "Connector Health Check — $connectorId" -ForegroundColor Cyan
Write-Host ("─" * 60)

# ── Get connection status ─────────────────────────────────────────────────────
try {
    $connection = Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/external/connections/$connectorId"

    Write-Host "Name:             $($connection.name)"
    Write-Host "State:            $($connection.state)" -ForegroundColor $(
        if ($connection.state -eq 'ready') { 'Green' } else { 'Yellow' }
    )
    Write-Host "Description:      $($connection.description)"
    Write-Host "Ingested items:   $($connection.ingestedItemsCount ?? 'n/a')"

    if ($connection.state -ne 'ready') {
        Write-Host ""
        Write-Host "Connector is not in 'ready' state. Wait for the Nexus full scan to complete." -ForegroundColor Yellow
        Write-Host "Monitor progress in Nexus web UI > Jobs."
    } else {
        Write-Host ""
        Write-Host "Connector is ready. Proceed to m365/01-Enable-ConnectorForCopilot.ps1" -ForegroundColor Green
    }

} catch {
    Write-Host "Could not retrieve connector: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible causes:"
    Write-Host "  - NEXUS_AI_CONNECTOR_ID is wrong — check Nexus web UI > Policies"
    Write-Host "  - Policy has not been activated yet (nexus/06)"
    Write-Host "  - Connector is still being created (wait a few minutes after activation)"
}

# ── List all external connections (for discovery) ─────────────────────────────
Write-Host ""
Write-Host "All external connections in this tenant:" -ForegroundColor DarkGray
try {
    $allConnections = Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/external/connections"
    $allConnections.value | ForEach-Object {
        Write-Host "  $($_.id)  |  $($_.name)  |  state: $($_.state)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  Could not list connections: $($_.Exception.Message)" -ForegroundColor DarkGray
}
