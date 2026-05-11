<#
.SYNOPSIS
    Enable the Nexus Graph Connector for Microsoft 365 Copilot.
    This is the "Give visibility to Copilot" step from Admin Guide §2.7 step 5.

.BACKGROUND
    When Nexus activates a policy (nexus/06), it creates a Microsoft Graph
    ExternalConnection named "<ENTRA_APP_NAME>-<policy-id>". The connector exists
    and is indexing content, but it is NOT visible to Copilot until an admin
    explicitly enables it.

    In the portal: admin.microsoft.com > Search & intelligence > Data sources
                   Find the connector > "Include in Copilot and org-wide search"

.AUTOMATION STATUS
    Partially automatable — beta API only, with an undocumented enum value.

    Research finding (2026-05-05):
      - Property 'enabledContentExperiences' exists on externalConnection in BETA API only.
      - v1.0 does NOT expose this property.
      - Enum value for Copilot is 'copilotSearch' (referenced in community/SDK but not in
        official PATCH reference docs — Microsoft has not formally documented it).
      - The PATCH reference only lists 'name', 'description', 'configuration' as updatable,
        but the conceptual guide confirms enabledContentExperiences is changeable.

    This script tries: PATCH /beta/external/connections/{id} with
      { "enabledContentExperiences": ["search", "copilotSearch"] }
    If that fails, it prints the manual portal steps.

    See: docs/ms-reference/graph-external-connection-update.md for full research.

.NOTES
    Admin Guide: §2.7 step 5b–d
    Run AFTER: nexus/06-Activate-Policy.ps1 (connector must exist)
    Requires: ExternalConnection.ReadWrite.All (Application permission — already on Nexus app)
#>

. "$PSScriptRoot/../_common/Config.ps1"
. "$PSScriptRoot/../_common/Connect-Graph.ps1"

$connectorId = $env:NEXUS_AI_CONNECTOR_ID

if (-not $connectorId) {
    throw "NEXUS_AI_CONNECTOR_ID not set in .env. Run nexus/06-Activate-Policy.ps1 first."
}

Write-Host ""
Write-Host "Enabling Graph Connector for M365 Copilot..." -ForegroundColor Cyan
Write-Host "Connector ID: $connectorId"

# ── Attempt 1: Graph v1.0 ────────────────────────────────────────────────────
$betaUrl = "https://graph.microsoft.com/beta/external/connections/$connectorId"
$v1Url   = "https://graph.microsoft.com/v1.0/external/connections/$connectorId"

# Beta only — v1.0 does not expose enabledContentExperiences.
# 'copilotSearch' is the undocumented-but-functional enum value for Copilot.
# 'search' enables org-wide Microsoft Search. Both together = full visibility.
$body = @{
    enabledContentExperiences = @("search", "copilotSearch")
} | ConvertTo-Json

$success = $false

# ── Step 1: Verify connector exists (v1.0 GET is fine) ───────────────────────
try {
    $connection = Invoke-MgGraphRequest -Method GET -Uri $v1Url -ErrorAction Stop
    Write-Host "Connector found: $($connection.name) (state: $($connection.state))" -ForegroundColor DarkGray
} catch {
    throw "Connector '$connectorId' not found. Verify NEXUS_AI_CONNECTOR_ID in .env and that nexus/06 has run."
}

# ── Step 2: Check current enabledContentExperiences via beta ─────────────────
try {
    $betaConnection = Invoke-MgGraphRequest -Method GET -Uri $betaUrl -ErrorAction Stop
    $current = $betaConnection.enabledContentExperiences
    Write-Host "Current enabledContentExperiences: $($current -join ', ')" -ForegroundColor DarkGray

    if ($current -contains "copilotSearch") {
        Write-Host "Connector is already enabled for Copilot." -ForegroundColor Green
        $success = $true
    }
} catch {
    Write-Host "Could not read beta connection properties: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ── Step 3: PATCH via beta to enable ─────────────────────────────────────────
if (-not $success) {
    try {
        Invoke-MgGraphRequest -Method PATCH -Uri $betaUrl `
            -Body $body -ContentType "application/json" -ErrorAction Stop
        Write-Host "SUCCESS: Connector enabled for Copilot via beta API." -ForegroundColor Green
        Write-Host "Note: Uses beta endpoint — 'copilotSearch' enum not formally documented by Microsoft." -ForegroundColor DarkGray
        Write-Host "      Monitor: docs/ms-reference/graph-external-connection-update.md for v1.0 promotion." -ForegroundColor DarkGray
        $success = $true
    } catch {
        Write-Host "Beta PATCH failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# ── Fall back to manual steps ─────────────────────────────────────────────────
if (-not $success) {
    Write-Host ""
    Write-Host "API automation unavailable for this step. Complete manually:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Open: https://admin.microsoft.com" -ForegroundColor White
    Write-Host "     Navigate to: Search & intelligence > Data sources"
    Write-Host ""
    Write-Host "  2. Find connector named: $($env:ENTRA_APP_NAME)-$connectorId" -ForegroundColor White
    Write-Host "     (or search for '$($env:ENTRA_APP_NAME)' in the connector list)"
    Write-Host ""
    Write-Host "  3. Click the connector. Find the toggle:" -ForegroundColor White
    Write-Host "     'Include in Copilot and org-wide search' → Enable"
    Write-Host "     (The guide calls this 'Give visibility to Copilot')"
    Write-Host ""
    Write-Host "  4. Confirm. Wait a few minutes for the change to propagate." -ForegroundColor White
    Write-Host ""
    Write-Host "After completing, the connector will appear in Copilot search results." -ForegroundColor Cyan
}

# ── Verify ────────────────────────────────────────────────────────────────────
if ($success) {
    Write-Host ""
    Write-Host "Next step: scripts/copilot/01-New-CustomConnector.ps1" -ForegroundColor Cyan
}
