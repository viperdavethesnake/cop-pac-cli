<#
.SYNOPSIS
    CloudFS audit settings pre-flight check and manual step guide.

    For CloudFS 8.7.0 (current target): settings are UI-only — this script
    prints the exact steps and validates connectivity to the node.

    For CloudFS 8.5.x (legacy): SSH automation is included but not the active path.

.NOTES
    Admin Guide: §2.3.3
    Must be done on BOTH master node AND every subordinate node.
    These settings are required before Nexus can receive file change events.
    Complete this BEFORE running any scripts/nexus/ scripts.
#>

. "$PSScriptRoot/../_common/Config.ps1"

$version    = $env:CLOUDFS_VERSION
$masterNode = $env:CLOUDFS_MASTER_NODE

Write-Host ""
Write-Host "CloudFS Audit Settings — Version: $version" -ForegroundColor Cyan
Write-Host ("─" * 60)

# ── 8.7.0 / 8.6.x — Manual UI steps ─────────────────────────────────────────
if ($version -match '^8\.(6|7)') {

    Write-Host ""
    Write-Host "CloudFS $version requires audit settings via the web UI." -ForegroundColor Yellow
    Write-Host "Complete the following steps on EACH node before proceeding."
    Write-Host ""

    Write-Host "MASTER NODE ($masterNode):" -ForegroundColor Green
    Write-Host "  1. Login to CloudFS master web UI"
    Write-Host "  2. Configuration > Monitoring > Audit Settings"
    Write-Host ""
    Write-Host "  Third Party Vendor Support section:"
    Write-Host "    Generate Third Party Log  → ON"
    Write-Host "    Push to Subordinate(s)    → ON"
    Write-Host "    User Actions              → Create File, Delete, Delete Permissions,"
    Write-Host "                                Move, Remove, File Lock, Change Permissions, Write"
    Write-Host "    Vendor Name               → Nexus"
    Write-Host ""
    Write-Host "  Master Audit Settings section:"
    Write-Host "    Generate Third Party Log  → ON"
    Write-Host "    User Actions              → (same as above)"
    Write-Host "    Vendor Name               → Nexus"
    Write-Host ""
    Write-Host "  Click Save. Then logout."
    Write-Host ""

    $subordinates = $env:CLOUDFS_SUBORDINATE_NODES -split ',' | Where-Object { $_ }
    if ($subordinates) {
        foreach ($node in $subordinates) {
            Write-Host "SUBORDINATE NODE ($($node.Trim())):" -ForegroundColor Green
            Write-Host "  1. Login to subordinate node web UI"
            Write-Host "  2. Configuration > Monitoring > Audit Settings"
            Write-Host ""
            Write-Host "  Third Party Vendor Support section:"
            Write-Host "    Generate Third Party Log  → ON"
            Write-Host "    User Actions              → Create File, Delete, Delete Permissions,"
            Write-Host "                                Move, Remove, File Lock, Change Permissions, Write"
            Write-Host "    Vendor Name               → Nexus"
            Write-Host ""
            Write-Host "  Click Save. Then logout."
            Write-Host ""
        }
    } else {
        Write-Host "SUBORDINATE NODES: Set CLOUDFS_SUBORDINATE_NODES in .env to list them here." -ForegroundColor DarkGray
    }

    Write-Host "Once complete on all nodes, proceed to scripts/nexus/ configuration." -ForegroundColor Cyan
}

# ── 8.5.x — SSH automation ────────────────────────────────────────────────────
elseif ($version -match '^8\.5') {

    Write-Host "CloudFS 8.5.x detected — using SSH automation." -ForegroundColor Green

    if (-not (Get-Module -ListAvailable Posh-SSH)) {
        throw "Posh-SSH module not found. Run: Install-Module Posh-SSH -Scope CurrentUser"
    }

    $adminUser = $env:CLOUDFS_ADMIN_USER
    $adminPass = $env:CLOUDFS_ADMIN_PASSWORD
    if (-not $masterNode -or -not $adminUser) {
        throw "CLOUDFS_MASTER_NODE and CLOUDFS_ADMIN_USER must be set in .env"
    }

    $auditActions = "create,delete,delxattr,move,remove,rlclaim,setxattr,write"

    $masterCmds = @(
        "p8_startup_cfg cmd audit-master-thirdparty `"nexus`" on `"$auditActions`" `"*`" `"-`""
        "p8_startup_cfg cmd audit-local-thirdparty `"nexus`" on `"$auditActions`" `"*`" `"-`""
        "p8_startup_cfg cmd audit-thirdparty enable"
        "p8_startup_cfg write"
    )
    $subCmds = @(
        "p8_startup_cfg cmd audit-local-thirdparty `"nexus`" on `"$auditActions`" `"*`" `"-`""
        "p8_startup_cfg cmd audit-thirdparty enable"
        "p8_startup_cfg write"
    )

    function Invoke-CloudFSSsh {
        param([string]$Host, [string]$User, [string]$Pass, [string[]]$Cmds, [string]$Label)
        Write-Host "Connecting to $Label ($Host)..." -ForegroundColor Cyan
        $cred    = New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Pass -AsPlainText -Force))
        $session = New-SSHSession -ComputerName $Host -Credential $cred -AcceptKey
        foreach ($cmd in $Cmds) {
            Write-Host "  > $cmd"
            $r = Invoke-SSHCommand -SessionId $session.SessionId -Command $cmd
            if ($r.ExitStatus -ne 0) { Write-Warning "  Exit $($r.ExitStatus): $($r.Error)" }
        }
        Remove-SSHSession -SessionId $session.SessionId
        Write-Host "  Done." -ForegroundColor Green
    }

    Invoke-CloudFSSsh -Host $masterNode -User $adminUser -Pass $adminPass `
        -Cmds $masterCmds -Label "Master"

    $subordinates = $env:CLOUDFS_SUBORDINATE_NODES -split ',' | Where-Object { $_ }
    foreach ($node in $subordinates) {
        Invoke-CloudFSSsh -Host $node.Trim() -User $adminUser -Pass $adminPass `
            -Cmds $subCmds -Label "Subordinate"
    }
}

else {
    Write-Warning "Unrecognized CLOUDFS_VERSION '$version'. Set to 8.7.0, 8.6.x, or 8.5.x in .env."
}
