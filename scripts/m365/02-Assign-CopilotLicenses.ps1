<#
.SYNOPSIS
    Report on M365 Copilot license availability and optionally assign licenses
    to a list of users or a group.

.NOTES
    Requires: User.ReadWrite.All (to assign licenses)
    The pre-flight script (entra/00) checks whether licenses exist in the tenant.
    This script handles the assignment side if needed.

    Typical Copilot license SKU: "Microsoft_365_Copilot" or similar.
    The exact SkuPartNumber varies by tenant purchase type — the script
    auto-detects all Copilot-related SKUs.
#>

. "$PSScriptRoot/../_common/Config.ps1"
. "$PSScriptRoot/../_common/Connect-Graph.ps1"

# ── Find Copilot SKU in tenant ────────────────────────────────────────────────
Write-Host "Scanning tenant for Copilot license SKUs..." -ForegroundColor Cyan

$allSkus = Get-MgSubscribedSku
$copilotSkus = $allSkus | Where-Object { $_.SkuPartNumber -match "copilot" }

if (-not $copilotSkus) {
    Write-Host "No Copilot SKUs found in this tenant." -ForegroundColor Red
    Write-Host "Purchase M365 Copilot licenses at admin.microsoft.com > Billing > Purchase services."
    exit 1
}

Write-Host ""
Write-Host "Copilot SKUs available:" -ForegroundColor Green
$copilotSkus | ForEach-Object {
    $available = $_.PrepaidUnits.Enabled - $_.ConsumedUnits
    Write-Host "  $($_.SkuPartNumber)  |  $($_.ConsumedUnits) used / $($_.PrepaidUnits.Enabled) total  |  $available available"
}

# ── Report users without Copilot license ─────────────────────────────────────
Write-Host ""
Write-Host "Checking which users have Copilot licenses assigned..." -ForegroundColor Cyan

$copilotSkuIds = $copilotSkus.SkuId
$usersWithCopilot = Get-MgUser -Filter "assignedLicenses/any(x:x/skuId eq $($copilotSkuIds[0]))" `
    -ConsistencyLevel eventual -All -ErrorAction SilentlyContinue

Write-Host "$($usersWithCopilot.Count) users currently have Copilot licenses assigned."

# ── Optional: assign to specific users ───────────────────────────────────────
# To assign licenses, populate $usersToAssign with UPNs and uncomment the block below.
# This is intentionally left as a manual trigger — license assignment affects billing.
$usersToAssign = @(
    # "user1@domain.com"
    # "user2@domain.com"
)

if ($usersToAssign.Count -gt 0) {
    $targetSkuId = $copilotSkus[0].SkuId
    foreach ($upn in $usersToAssign) {
        try {
            $user = Get-MgUser -UserId $upn
            Set-MgUserLicense -UserId $user.Id `
                -AddLicenses @{ SkuId = $targetSkuId } `
                -RemoveLicenses @()
            Write-Host "  Assigned Copilot license to: $upn" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to assign to $upn`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host ""
    Write-Host "To assign licenses: edit `$usersToAssign in this script and re-run." -ForegroundColor DarkGray
    Write-Host "Or assign via portal: admin.microsoft.com > Users > Active users > select user > Licenses" -ForegroundColor DarkGray
}
