<#
.SYNOPSIS
    Guided setup for the Copilot Studio agent (Path A — manual workflow).
    Run this script, then follow its output step by step in the browser.

.NOTES
    Admin Guide: §2.10.4B–C
    This does NOT use the Nexus web UI wizard (Path B).

    Prerequisites (this script validates all of these):
      - Custom connector created and tested  (copilot/01 complete)
      - NEXUS_AI_CONNECTOR_ID set in .env    (from nexus/06)
      - COPILOT_AGENT_NAME set in .env       (or defaults to 'Panzura Nexus Agent')

    Agent tools wired from the custom connector:
      SearchNexus       POST /v1.0/search/query
      GetExternalItem   GET  /v1.0/external/connections/{id}/items/{id}

    Model: GPT-4o or latest available in your tenant's Copilot Studio.

    When done: run scripts/copilot/03-Publish-Agent.ps1
#>

$script:RequiredVars = @('ENTRA_TENANT_ID', 'NEXUS_AI_CONNECTOR_ID')
. "$PSScriptRoot/../_common/Config.ps1"

$agentName        = $env:COPILOT_AGENT_NAME ?? "Panzura Nexus Agent"
$connectorId      = $env:NEXUS_AI_CONNECTOR_ID
$contentSource    = "/external/connections/$connectorId"
$instructionsFile = "$PSScriptRoot/../../artifacts/agent/agent-instructions.txt"

# ── Validate prerequisites ────────────────────────────────────────────────────
Write-Host ""
Write-Host "Validating prerequisites..." -ForegroundColor Cyan

$prereqFail = $false

if (-not $connectorId) {
    Write-Host "  [FAIL] NEXUS_AI_CONNECTOR_ID not set — run nexus/06-Activate-Policy.ps1 first" -ForegroundColor Red
    $prereqFail = $true
} else {
    Write-Host "  [PASS] NEXUS_AI_CONNECTOR_ID = $connectorId" -ForegroundColor Green
}

if (-not (Test-Path $instructionsFile)) {
    Write-Host "  [WARN] Agent instructions file not found: $instructionsFile" -ForegroundColor Yellow
} else {
    Write-Host "  [PASS] Agent instructions file found" -ForegroundColor Green
}

if ($prereqFail) { exit 1 }

# ── Header ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Copilot Studio Agent Setup" -ForegroundColor Cyan
Write-Host "Agent name:     $agentName"
Write-Host "contentSource:  $contentSource"
Write-Host ("─" * 60)
Write-Host ""
Write-Host "Open: https://copilotstudio.microsoft.com" -ForegroundColor White
Write-Host ""

# ── STEP A — Create a blank agent ─────────────────────────────────────────────
Write-Host "STEP A — Create a blank agent" -ForegroundColor Green
Write-Host "  Agents (left nav) > + New agent > Skip to configure"
Write-Host "  Name:    $agentName" -ForegroundColor Cyan
Write-Host "  Click:   Create"
Write-Host ""

# ── STEP B — Set description, instructions, and model ─────────────────────────
Write-Host "STEP B — Configure the agent" -ForegroundColor Green
Write-Host "  Overview tab > Edit"
Write-Host ""
Write-Host "  Instructions — paste everything between the lines below:" -ForegroundColor White
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

if (Test-Path $instructionsFile) {
    Get-Content $instructionsFile
} else {
    Write-Host "[instructions file not found — check artifacts/agent/agent-instructions.txt]" -ForegroundColor Red
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Click Save after pasting."
Write-Host ""

# ── STEP C — Add SearchNexus tool ─────────────────────────────────────────────
Write-Host "STEP C — Add the SearchNexus tool" -ForegroundColor Green
Write-Host "  Overview > Tools > + Add tool"
Write-Host "  Search for: 'Search Nexus Data'  (your custom connector)"
Write-Host "  Click Add."
Write-Host ""
Write-Host "  Then: select the tool > Inputs tab > configure each input:"
Write-Host "    query          → Dynamically fill from AI"
Write-Host "    filter         → Dynamically fill from AI"
Write-Host "    offset         → Dynamically fill from AI"
Write-Host "    contentSource  → Custom value:" -ForegroundColor White
Write-Host "      $contentSource" -ForegroundColor Cyan
Write-Host "  Click Save."
Write-Host ""

# ── STEP D — Add GetExternalItem tool ─────────────────────────────────────────
Write-Host "STEP D — Add the GetExternalItem tool" -ForegroundColor Green
Write-Host "  Overview > Tools > + Add tool"
Write-Host "  Search for: 'Get External Item In Chunks'  (same custom connector)"
Write-Host "  Click Add."
Write-Host ""
Write-Host "  Then: select the tool > Inputs tab > configure each input:"
Write-Host "    connection-id  → Dynamically fill from AI"
Write-Host "    item-id        → Dynamically fill from AI"
Write-Host "    chunk          → Dynamically fill from AI"
Write-Host "    chunkSize      → Custom value: 60000" -ForegroundColor Cyan
Write-Host "  Click Save."
Write-Host ""

# ── STEP E — Test ─────────────────────────────────────────────────────────────
Write-Host "STEP E — Test the agent" -ForegroundColor Green
Write-Host "  Right pane > Test agent > New conversation"
Write-Host "  If a connection popup appears — click Allow."
Write-Host "  Try a natural-language query against your ingested CloudFS data."
Write-Host "  Expect the agent to return file names, paths, and summaries."
Write-Host ""
Write-Host ("─" * 60)
Write-Host "When the agent responds correctly, run:" -ForegroundColor Cyan
Write-Host "  scripts/copilot/03-Publish-Agent.ps1" -ForegroundColor Cyan
