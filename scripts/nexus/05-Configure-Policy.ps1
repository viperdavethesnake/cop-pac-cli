<#
.SYNOPSIS
    Create a Data Insight Policy in Nexus that links Storage, AI, and IAM plugins
    with rules. This is the core configuration that governs what gets ingested.

.NOTES
    Admin Guide: §2.8.5
    A policy goes through 5 steps: Select Plugins → Configuration → Define Rules
                                    → Schedule → Summary
    IMPORTANT: Only one plugin configuration per CloudFS ring. Creating multiple
    plugins from the same ring will cause policies to get stuck in "Activating".

    After activation, Nexus creates a Graph Connector named <Panzura-Nexus-policy-id>.
    That connector ID becomes NEXUS_AI_CONNECTOR_ID — needed for the Copilot agent.
#>

. "$PSScriptRoot/../_common/Config.ps1"

$nexusBase = "https://$($env:NEXUS_IP)"

# ── Validate plugin IDs are set ───────────────────────────────────────────────
$storagePluginId = $env:NEXUS_STORAGE_PLUGIN_ID
$aiPluginId      = $env:NEXUS_AI_PLUGIN_ID
$iamPluginId     = $env:NEXUS_IAM_PLUGIN_ID

if (-not $storagePluginId) { throw "NEXUS_STORAGE_PLUGIN_ID not set. Run 01-Configure-StoragePlugin.ps1 first." }
if (-not $aiPluginId)      { throw "NEXUS_AI_PLUGIN_ID not set. Run 02-Configure-AiPlugin.ps1 first." }
if (-not $iamPluginId)     { throw "NEXUS_IAM_PLUGIN_ID not set. Run 03-Configure-IamPlugin.ps1 first." }

# ── Auth ──────────────────────────────────────────────────────────────────────
$loginBody = @{ username = $env:NEXUS_ADMIN_USER; password = $env:NEXUS_ADMIN_PASSWORD } | ConvertTo-Json
$session   = Invoke-RestMethod -Uri "$nexusBase/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$headers   = @{ Authorization = "Bearer $($session.token)" }

# ── Create policy ─────────────────────────────────────────────────────────────
$policyBody = @{
    name            = "nexus-primary-policy"
    description     = "Primary data insight policy for CloudFS → Copilot"

    # Step 1 — Plugins
    sourcePluginId  = $storagePluginId
    destPluginId    = $aiPluginId
    iamPluginId     = $iamPluginId

    # Step 2 — Configuration
    includeDirectories = @("/cloudfs/")   # TODO: parameterize — must start with /cloudfs/
    parseOcr           = $false            # OCR significantly increases scan time
    overrideAcls       = $false            # false = append users/groups to existing ACL

    # Step 3 — Rules
    # TODO: populate with rule IDs from 04-Configure-Rules.ps1 output
    ruleIds = @()

    # Step 4 — Schedule
    liveAccessMonitoring = $true
    fullScanOnActivation = $true
    schedule             = $null   # null = no recurring schedule

} | ConvertTo-Json -Depth 5

# TODO: Confirm endpoint path
$result = Invoke-RestMethod -Uri "$nexusBase/api/policies" `
    -Method Post -Body $policyBody -ContentType "application/json" -Headers $headers

$policyId = $result.id
Write-Host "Policy created: $policyId" -ForegroundColor Green

Set-EnvValue 'NEXUS_POLICY_ID' $result.id
Write-Host "Run next: scripts/nexus/06-Activate-Policy.ps1" -ForegroundColor Cyan
