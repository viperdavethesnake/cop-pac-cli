<#
.SYNOPSIS
    Guided publish of the Copilot Studio agent to Teams + Microsoft 365 Copilot,
    and submission for admin approval.

.NOTES
    Admin Guide: §2.10.4D, §2.10.5F

    Publishing is a Copilot Studio UI workflow — there is no PAC CLI command for it.

    What this script walks you through:
      1. Publish the agent (makes it available on all configured channels)
      2. Add the Microsoft 365 Copilot + Teams channel
      3. Submit for org-wide admin approval
      4. Admin approval (admin.cloud.microsoft.com — Global Admin required)

    After admin approval, users access the agent at:
      https://m365.cloud.microsoft/chat > Agents > All agents
#>

$script:RequiredVars = @('NEXUS_AI_CONNECTOR_ID')
. "$PSScriptRoot/../_common/Config.ps1"

$agentName = $env:COPILOT_AGENT_NAME ?? "Panzura Nexus Agent"

Write-Host ""
Write-Host "Publishing: $agentName" -ForegroundColor Cyan
Write-Host ("─" * 60)
Write-Host ""
Write-Host "Open: https://copilotstudio.microsoft.com" -ForegroundColor White
Write-Host "Select agent: $agentName"
Write-Host ""

# ── STEP A — Publish ──────────────────────────────────────────────────────────
Write-Host "STEP A — Publish the agent" -ForegroundColor Green
Write-Host "  Top-right corner > Publish button"
Write-Host "  Confirm in the dialog."
Write-Host "  Wait for 'Your agent is published' confirmation (usually < 1 minute)."
Write-Host ""

# ── STEP B — Enable Teams + M365 Copilot channel ─────────────────────────────
Write-Host "STEP B — Add the Microsoft 365 Copilot channel" -ForegroundColor Green
Write-Host "  Channels (top menu) > Microsoft 365 Copilot"
Write-Host "  Toggle: Enable in Microsoft 365 Copilot → ON"
Write-Host "  This also enables the Teams channel automatically."
Write-Host "  Click Save."
Write-Host ""

# ── STEP C — Submit for admin approval ───────────────────────────────────────
Write-Host "STEP C — Submit for org-wide availability" -ForegroundColor Green
Write-Host "  Publish (top menu) > Share agent"
Write-Host "  Select: 'Share to your organization'"
Write-Host "  Click Submit for admin approval."
Write-Host "  Status will show 'Pending approval'."
Write-Host ""

# ── STEP D — Admin approval (Global Admin required) ───────────────────────────
Write-Host "STEP D — Admin approval  (Global Administrator)" -ForegroundColor Green
Write-Host "  Open: https://admin.cloud.microsoft.com" -ForegroundColor White
Write-Host "  Navigate: Copilot > Agents > Requests tab"
Write-Host "  Find: $agentName" -ForegroundColor Cyan
Write-Host "  Click: vertical ellipsis (⋮) > Publish to org"
Write-Host "  Review and Publish."
Write-Host ""
Write-Host "  The request may take a few minutes to appear after Step C."
Write-Host ""

# ── STEP E — Verify ───────────────────────────────────────────────────────────
Write-Host "STEP E — Verify availability" -ForegroundColor Green
Write-Host "  After admin approval (usually within minutes):"
Write-Host ""
Write-Host "  Microsoft 365 Copilot:"
Write-Host "    https://m365.cloud.microsoft/chat > Agents tab > All agents"
Write-Host "    Find '$agentName' and start a conversation."
Write-Host ""
Write-Host "  Microsoft Teams:"
Write-Host "    Teams app > Apps > search '$agentName' > Add"
Write-Host ""

Write-Host ("─" * 60)
Write-Host "Setup complete. The Nexus agent is live." -ForegroundColor Green
Write-Host ""
Write-Host "If users report the agent can't find files, verify:" -ForegroundColor DarkGray
Write-Host "  1. Connector state: scripts/m365/03-Verify-ConnectorIngestion.ps1" -ForegroundColor DarkGray
Write-Host "  2. Copilot visibility: scripts/m365/01-Enable-ConnectorForCopilot.ps1" -ForegroundColor DarkGray
Write-Host "  3. User has an M365 Copilot license: scripts/m365/02-Assign-CopilotLicenses.ps1" -ForegroundColor DarkGray
