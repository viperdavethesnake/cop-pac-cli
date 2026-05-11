<#
.SYNOPSIS
    Entry point for new users. Run this first.

    Sets up your local environment and verifies everything is ready
    before you run any deployment scripts.

    Usage (from project root):
        pwsh start.ps1

    Prerequisites:
        macOS with Homebrew and PowerShell installed.
        If you haven't done that yet, run this first in a standard Terminal:
            bash setup/01-Install-Homebrew-Tools.sh
        Then open a NEW terminal tab and run:
            pwsh start.ps1
#>

$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot

Write-Host ""
Write-Host "Nexus Automation — Getting Started" -ForegroundColor Cyan
Write-Host ("─" * 50)
Write-Host ""

# ── Pre-flight: confirm step 01 (brew tools) was run ─────────────────────────
$missing = @()
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { $missing += "dotnet" }
if (-not (Get-Command pac    -ErrorAction SilentlyContinue)) { $missing += "pac" }

if ($missing) {
    Write-Host "Missing tools: $($missing -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "Step 01 (Homebrew tools) has not been run yet, or you need to open" -ForegroundColor Yellow
    Write-Host "a new terminal after running it." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Open Terminal (bash/zsh — not pwsh)"
    Write-Host "  2. Run:  bash setup/01-Install-Homebrew-Tools.sh"
    Write-Host "  3. Open a NEW terminal tab"
    Write-Host "  4. Run:  pwsh start.ps1"
    exit 1
}

# ── Step 2: Install PowerShell modules ───────────────────────────────────────
Write-Host "Step 1/2 — Installing PowerShell modules..." -ForegroundColor Cyan
Write-Host ""
& "$scriptRoot/setup/02-Install-PSModules.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Module installation failed. Fix the error above and re-run: pwsh start.ps1" -ForegroundColor Red
    exit 1
}

# ── Step 3: Verify environment ────────────────────────────────────────────────
Write-Host ""
Write-Host "Step 2/2 — Verifying environment..." -ForegroundColor Cyan
Write-Host ""
& "$scriptRoot/setup/03-Verify-Setup.ps1"
exit $LASTEXITCODE
