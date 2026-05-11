<#
.SYNOPSIS
    Verify the complete development environment is correctly installed.
    Run this after 01 and 02. All checks should be green before running
    any scripts in the main project.

    Usage:
        pwsh setup/03-Verify-Setup.ps1
#>

$pass = 0; $fail = 0; $warn = 0
$results = @()

function Check {
    param(
        [string]$Label,
        [scriptblock]$Test,
        [string]$FixCmd = "",
        [string]$FixNote = ""
    )
    try {
        $detail = & $Test
        $script:results += [PSCustomObject]@{ Status="PASS"; Label=$Label; Detail=$detail; Fix="" }
        $script:pass++
    } catch {
        $msg = $_.Exception.Message -replace "`n"," "
        $fix = @($FixCmd, $FixNote) | Where-Object { $_ } | Select-Object -First 2
        $script:results += [PSCustomObject]@{ Status="FAIL"; Label=$Label; Detail=$msg; Fix=($fix -join " | ") }
        $script:fail++
    }
}

function Warn {
    param([string]$Label, [string]$Detail, [string]$Fix = "")
    $script:results += [PSCustomObject]@{ Status="WARN"; Label=$Label; Detail=$Detail; Fix=$Fix }
    $script:warn++
}

Write-Host ""
Write-Host "Nexus Automation — Environment Verification" -ForegroundColor Cyan
Write-Host "Platform: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)"
Write-Host "Architecture: $([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture)"
Write-Host ("─" * 65)

# ── PowerShell version ────────────────────────────────────────────────────────
Check "PowerShell version" {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "Version $($PSVersionTable.PSVersion) — need 7.x"
    }
    "pwsh $($PSVersionTable.PSVersion) ✓"
} -FixCmd "brew install powershell"

# ── .NET SDK ──────────────────────────────────────────────────────────────────
Check ".NET SDK" {
    $v = dotnet --version 2>&1
    if ($LASTEXITCODE -ne 0) { throw "dotnet not on PATH" }
    ".NET $v ✓"
} -FixCmd "brew install powershell" -FixNote "(dotnet is installed as a PowerShell dependency)"

# ── PAC CLI ───────────────────────────────────────────────────────────────────
Check "PAC CLI (pac)" {
    if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
        throw "pac not found on PATH"
    }
    $out = pac help 2>&1 | Select-String "^Version:"
    if (-not $out) { throw "pac found but version check failed" }
    # 2.x crashes on macOS ARM (WAM broker NullRef bug) — must use 1.x
    if ($out -match "Version: 2\.") {
        throw "PAC CLI $out is installed but 2.x crashes on macOS ARM. Downgrade: dotnet tool uninstall --global Microsoft.PowerApps.CLI.Tool && dotnet tool install --global Microsoft.PowerApps.CLI.Tool --version 1.33.5"
    }
    "$out ✓"
} -FixCmd "dotnet tool install --global Microsoft.PowerApps.CLI.Tool --version 1.33.5" `
  -FixNote "Also ensure DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec and ~/.dotnet/tools is on PATH"

# ── DOTNET_ROOT ───────────────────────────────────────────────────────────────
Check "DOTNET_ROOT env var" {
    if (-not $env:DOTNET_ROOT) { throw "DOTNET_ROOT is not set" }
    if (-not (Test-Path $env:DOTNET_ROOT)) { throw "DOTNET_ROOT=$($env:DOTNET_ROOT) path does not exist" }
    "$($env:DOTNET_ROOT) ✓"
} -FixNote "Add to ~/.zshrc: export DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec"

# ── PS Modules ────────────────────────────────────────────────────────────────
$requiredModules = @(
    @{ Name = "Microsoft.Graph";                               MinVer = "2.0.0" }
    @{ Name = "Microsoft.PowerApps.Administration.PowerShell"; MinVer = "2.0.0" }
    @{ Name = "Microsoft.PowerApps.PowerShell";                MinVer = "1.0.0" }
    @{ Name = "Posh-SSH";                                      MinVer = "3.0.0" }
    @{ Name = "powershell-yaml";                               MinVer = "0.4.0" }
)

foreach ($mod in $requiredModules) {
    Check "PS Module: $($mod.Name)" {
        $m = Get-Module -ListAvailable $mod.Name -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending | Select-Object -First 1
        if (-not $m) { throw "Not installed" }
        if ([version]$m.Version -lt [version]$mod.MinVer) {
            throw "v$($m.Version) installed, need >= $($mod.MinVer)"
        }
        "v$($m.Version) ✓"
    } -FixCmd "pwsh setup/02-Install-PSModules.ps1"
}

# ── .env file ─────────────────────────────────────────────────────────────────
$envPath = Join-Path $PSScriptRoot "../.env"
if (Test-Path $envPath) {
    Check ".env file exists" { ".env found at $envPath ✓" }
} else {
    Warn ".env file" ".env not found — project scripts will not run" `
        "cp .env.example .env  then fill in values"
}

# ── PAC CLI can list commands (functional test) ───────────────────────────────
Check "PAC CLI: connector command" {
    $out = pac connector help 2>&1 | Select-String "create|list|download"
    if (-not $out) { throw "connector sub-commands not found in pac output" }
    "pac connector available ✓"
} -FixNote "If this fails, DOTNET_ROOT is likely wrong"

Check "PAC CLI: copilot command" {
    $out = pac copilot help 2>&1 | Select-String "create|list|extract"
    if (-not $out) { throw "copilot sub-commands not found in pac output" }
    "pac copilot available ✓"
} -FixNote "If this fails, DOTNET_ROOT is likely wrong"

# ── Print results ─────────────────────────────────────────────────────────────
Write-Host ""
foreach ($r in $results) {
    $color = switch ($r.Status) {
        "PASS" { "Green" }; "FAIL" { "Red" }; "WARN" { "Yellow" }
    }
    $icon = switch ($r.Status) {
        "PASS" { "[PASS]" }; "FAIL" { "[FAIL]" }; "WARN" { "[WARN]" }
    }
    Write-Host "$icon  $($r.Label)" -ForegroundColor $color
    Write-Host "       $($r.Detail)" -ForegroundColor DarkGray
    if ($r.Fix) {
        Write-Host "       Fix: $($r.Fix)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host ("─" * 65)
$statusColor = if ($fail -gt 0) { "Red" } elseif ($warn -gt 0) { "Yellow" } else { "Green" }
Write-Host "Results: $pass PASS  |  $warn WARN  |  $fail FAIL" -ForegroundColor $statusColor

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "Fix the FAIL items above, then re-run this script." -ForegroundColor Red
    Write-Host "See setup/README.md for troubleshooting details." -ForegroundColor DarkGray
    exit 1
} else {
    Write-Host ""
    Write-Host "Environment is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next: copy .env.example to .env and fill in your credentials." -ForegroundColor Cyan
    Write-Host "Then run: pwsh scripts/entra/00-Validate-Prerequisites.ps1"
}
