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

# ── .env Stage 1 keys ─────────────────────────────────────────────────────────
$envPath     = Join-Path $PSScriptRoot "../.env"
$envTenantId = $null

Check ".env Stage 1 keys" {
    if (-not (Test-Path $envPath)) {
        throw ".env not found — run: cp .env.example .env  then fill in Stage 1 values"
    }
    $envVals = @{}
    Get-Content $envPath | Where-Object { $_ -match '^[^#].*=' } | ForEach-Object {
        $parts = $_ -split '=', 2
        $envVals[$parts[0].Trim()] = ($parts[1] -replace '\s*#.*$', '').Trim()
    }
    $required = @('ENTRA_TENANT_ID', 'ENTRA_APP_NAME', 'CONNECTOR_NAME')
    $missing  = $required | Where-Object { -not $envVals[$_] }
    if ($missing) {
        throw "Missing required values in .env: $($missing -join ', ')"
    }
    $script:envTenantId = $envVals['ENTRA_TENANT_ID']
    "ENTRA_TENANT_ID, ENTRA_APP_NAME, CONNECTOR_NAME all set ✓"
} -FixCmd "cp .env.example .env" -FixNote "Then fill in: ENTRA_TENANT_ID, ENTRA_APP_NAME, CONNECTOR_NAME"

# ── PAC CLI authentication ────────────────────────────────────────────────────
Check "PAC CLI: authenticated to correct tenant" {
    # Use pac auth list to check for active profile — more reliable than pac org who exit code
    $authList   = pac auth list 2>&1
    $activeLine = $authList | Where-Object { $_ -match '^\[?\d+\]?\s+\*' -or $_ -match '^\s*\*' } | Select-Object -First 1
    if (-not $activeLine) {
        $tid = if ($envTenantId) { $envTenantId } else { "<fill ENTRA_TENANT_ID in .env first>" }
        throw "Not authenticated — run: pac auth create --tenant $tid"
    }

    # Use pac org who to extract tenant from Environment ID line
    $who       = pac org who 2>&1
    $envIdLine = $who | Where-Object { $_ -match 'Environment ID' } | Select-Object -First 1
    $pacTenant = if ($envIdLine -match 'Default-([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') { $matches[1] } else { $null }

    if ($envTenantId -and $pacTenant -and $pacTenant -ne $envTenantId) {
        throw "Wrong tenant — PAC CLI connected to $pacTenant but .env specifies $envTenantId`nFix: pac auth clear  then  pac auth create --tenant $envTenantId"
    }

    $userMatch  = $activeLine -match '(\S+@\S+)'
    $user       = if ($userMatch) { $matches[1] } else { "unknown" }
    $tenantNote = if ($pacTenant) { "tenant $pacTenant ✓" } else { "tenant unverifiable — proceeding" }
    "Connected as $user — $tenantNote"
} -FixCmd "pac auth create --tenant $envTenantId" `
  -FixNote "Sign in with your Global Admin account for the target tenant"

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
    # If the only failure is PAC CLI auth and we have a tenant ID, offer to fix it now
    $pacAuthFail = $results | Where-Object { $_.Status -eq "FAIL" -and $_.Label -like "PAC CLI: authenticated*" }
    $otherFails  = $results | Where-Object { $_.Status -eq "FAIL" -and $_.Label -notlike "PAC CLI: authenticated*" }

    if ($pacAuthFail -and -not $otherFails -and $envTenantId) {
        Write-Host ""
        Write-Host "The only failure is PAC CLI authentication." -ForegroundColor Yellow
        $answer = Read-Host "Fix it now? This will open a browser for tenant $envTenantId [Y/n]"
        if ($answer -eq '' -or $answer -match '^[Yy]') {
            Write-Host ""
            # Clear any wrong-tenant session first
            $authList  = pac auth list 2>&1
            $hasTenant = $authList | Where-Object { $_ -match '([0-9a-f-]{36})' -and $_ -match 'Tenant' }
            if ($hasTenant) { pac auth clear | Out-Null }
            pac auth create --tenant $envTenantId
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "Authenticated. Re-running verification..." -ForegroundColor Green
                Write-Host ""
                & $PSCommandPath
                exit $LASTEXITCODE
            } else {
                Write-Host "Authentication failed. Try manually: pac auth create --tenant $envTenantId" -ForegroundColor Red
                exit 1
            }
        }
    }

    Write-Host ""
    Write-Host "Fix the FAIL items above, then re-run this script." -ForegroundColor Red
    Write-Host "See setup/README.md for troubleshooting details." -ForegroundColor DarkGray
    exit 1
} else {
    Write-Host ""
    Write-Host "Environment is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Run next: pwsh scripts/entra/00-Validate-Prerequisites.ps1" -ForegroundColor Cyan
}
