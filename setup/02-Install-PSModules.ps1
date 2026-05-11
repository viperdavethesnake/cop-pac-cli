<#
.SYNOPSIS
    Install all required PowerShell modules for Nexus automation.
    Run this in pwsh (PowerShell 7.x) — NOT in bash.

    Usage:
        pwsh setup/02-Install-PSModules.ps1

.NOTES
    Tested: pwsh 7.6.1, macOS Apple Silicon
    Microsoft.Graph is large (~300MB, ~40 sub-modules). Allow 3-5 minutes.
    All modules install to CurrentUser scope (~/.local/share/powershell/Modules/)
    so no sudo is required.
#>

# Fail immediately if running in wrong PS version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "This script requires PowerShell 7+. You are running $($PSVersionTable.PSVersion). Run 'pwsh' first."
    exit 1
}

$modules = @(
    @{
        Name        = "Microsoft.Graph"
        Version     = "2.36.1"
        Description = "Microsoft Graph PowerShell SDK — Entra ID, users, apps, permissions"
        Note        = "Large module (~300MB). Takes 3-5 minutes."
    }
    @{
        Name        = "Microsoft.PowerApps.Administration.PowerShell"
        Version     = "2.0.217"
        Description = "Power Platform Admin — environments, app users, roles"
        Note        = ""
    }
    @{
        Name        = "Microsoft.PowerApps.PowerShell"
        Version     = "1.0.45"
        Description = "Power Apps user operations — connectors, apps"
        Note        = ""
    }
    @{
        Name        = "Posh-SSH"
        Version     = "3.2.7"
        Description = "SSH client — used for CloudFS 8.5.x audit settings"
        Note        = ""
    }
    @{
        Name        = "powershell-yaml"
        Version     = "0.4.7"
        Description = "YAML parser — converts connector swagger YAML to JSON for PAC CLI"
        Note        = ""
    }
)

Write-Host ""
Write-Host "Nexus Automation — PowerShell Module Installer" -ForegroundColor Cyan
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Host "Module path: $($env:PSModulePath -split ':' | Where-Object { $_ -match $env:HOME } | Select-Object -First 1)"
Write-Host ("─" * 60)

foreach ($mod in $modules) {
    Write-Host ""
    Write-Host "Installing: $($mod.Name)" -ForegroundColor Cyan
    if ($mod.Note) { Write-Host "  Note: $($mod.Note)" -ForegroundColor DarkGray }

    $existing = Get-Module -ListAvailable $mod.Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1

    if ($existing) {
        Write-Host "  Already installed: v$($existing.Version)" -ForegroundColor DarkGray
        if ([version]$existing.Version -ge [version]$mod.Version) {
            Write-Host "  [SKIP] Version is current." -ForegroundColor Green
            continue
        }
        Write-Host "  Updating to v$($mod.Version)..." -ForegroundColor Yellow
    }

    try {
        Install-Module $mod.Name -Scope CurrentUser -Force -AcceptLicense -ErrorAction Stop
        $installed = Get-Module -ListAvailable $mod.Name | Sort-Object Version -Descending | Select-Object -First 1
        Write-Host "  [OK] Installed v$($installed.Version)" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Try manually: Install-Module $($mod.Name) -Scope CurrentUser -Force -Verbose" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host ("─" * 60)
Write-Host "Done. Run the verification script next:" -ForegroundColor Green
Write-Host "  pwsh setup/03-Verify-Setup.ps1"
