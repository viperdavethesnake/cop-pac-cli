<#
.SYNOPSIS
    Activate the Nexus policy. This triggers connector creation in Microsoft 365
    and begins live monitoring / full scan (depending on policy schedule settings).

.NOTES
    Admin Guide: §2.8.5, §2.7
    After activation, Nexus creates a Graph Connector named <Panzura-Nexus-policy-id>.
    You must then:
      1. Log in to the Microsoft cloud admin site
      2. Find the connector named "Nexus" in the Connector list
      3. Click "Give visibility to Copilot" and confirm
    This manual step cannot currently be automated (no public API).

    The AI Connector ID is displayed in Nexus web UI > Policies.
    It is needed as the contentSource for the Copilot agent:
      /external/connections/<AI-CONNECTOR-ID>
#>

. "$PSScriptRoot/../_common/Config.ps1"

$nexusBase = "https://$($env:NEXUS_IP)"
$policyId  = $env:NEXUS_POLICY_ID

if (-not $policyId) { throw "NEXUS_POLICY_ID not set. Run 05-Configure-Policy.ps1 first." }

# ── Auth ──────────────────────────────────────────────────────────────────────
$loginBody = @{ username = $env:NEXUS_ADMIN_USER; password = $env:NEXUS_ADMIN_PASSWORD } | ConvertTo-Json
$session   = Invoke-RestMethod -Uri "$nexusBase/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$headers   = @{ Authorization = "Bearer $($session.token)" }

# ── Activate policy ───────────────────────────────────────────────────────────
$activateBody = @{
    dryRun              = $false   # set true to test rules without ingesting data
    startImmediateFullScan = $true
} | ConvertTo-Json

# TODO: Confirm endpoint path
$result = Invoke-RestMethod -Uri "$nexusBase/api/policies/$policyId/activate" `
    -Method Put -Body $activateBody -ContentType "application/json" -Headers $headers

Write-Host "Policy $policyId activated." -ForegroundColor Green

# ── Fetch AI Connector ID ─────────────────────────────────────────────────────
# TODO: Poll policy status until connector ID is populated
# TODO: Confirm endpoint for fetching policy details including connector ID
$policy = Invoke-RestMethod -Uri "$nexusBase/api/policies/$policyId" `
    -Method Get -Headers $headers

$connectorId = $policy.aiConnectorId   # TODO: confirm actual field name
if ($connectorId) {
    Set-EnvValue 'NEXUS_AI_CONNECTOR_ID' $connectorId
    Write-Host ""
    Write-Host "AI Connector ID : $connectorId" -ForegroundColor Cyan
    Write-Host "contentSource   : /external/connections/$connectorId"
}

Write-Host ""
Write-Host "Manual step required:" -ForegroundColor Yellow
Write-Host "  1. Log in to Microsoft 365 admin (admin.microsoft.com)"
Write-Host "  2. Search > Connectors > find 'Nexus'"
Write-Host "  3. Click 'Give visibility to Copilot' and confirm"
