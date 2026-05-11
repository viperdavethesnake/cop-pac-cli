# Environment Setup Guide

Complete setup guide for the Nexus automation toolchain on macOS Apple Silicon (arm64).

Tested on: macOS 26.4.1, Apple Silicon (M-series), 2026-05-05

---

## What Gets Installed

| Tool | Version Tested | Purpose |
|---|---|---|
| Homebrew | 5.1.9 | macOS package manager — installs everything else |
| PowerShell | 7.6.1 | Cross-platform pwsh — runs all `.ps1` scripts |
| .NET SDK | 10.0.107 | Required by PowerShell and PAC CLI |
| Node.js | 25.9.0 | Required only if using npm-based tooling |
| PAC CLI | 2.7.4 | Power Platform CLI — creates connectors and agents |
| Microsoft.Graph (PS module) | 2.36.1 | Entra ID app registration, permissions, Graph API |
| Microsoft.PowerApps.Administration.PowerShell | 2.0.217 | Power Platform admin operations |
| Microsoft.PowerApps.PowerShell | 1.0.45 | Power Apps user-level operations |
| Posh-SSH | 3.2.7 | SSH to CloudFS nodes (8.5.x only) |

---

## Quick Start

If you just want to run everything and read later:

```bash
# Step 1 — macOS tools (run in Terminal / zsh)
bash setup/01-Install-Homebrew-Tools.sh

# Step 2 — open a NEW terminal tab, then:
pwsh setup/02-Install-PSModules.ps1

# Step 3 — verify everything
pwsh setup/03-Verify-Setup.ps1
```

If Step 3 shows all green, you're done.

---

## Detailed Walkthrough

### Prerequisites

- macOS on Apple Silicon (M1/M2/M3/M4 — arm64 architecture)
- An internet connection
- Terminal access (zsh is the default on modern macOS)
- You do NOT need Xcode or any developer tools pre-installed — Homebrew handles it

### Step 1 — Homebrew

Homebrew is the macOS package manager. If you already have it, skip this.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After install, follow any instructions it prints about adding Homebrew to your PATH (typically adding a line to `~/.zprofile`). Then verify:

```bash
brew --version
# Homebrew 5.x.x
```

### Step 2 — PowerShell 7.x

> **Apple Silicon gotcha:** `brew install --cask powershell` does NOT work — the cask was removed.
> Use the formula instead:

```bash
brew install powershell
```

This also installs .NET (a dependency) and icu4c. Takes 1–2 minutes.

Verify:
```bash
pwsh --version
# PowerShell 7.6.1
```

From this point forward, always use `pwsh` to run scripts — not `powershell` (that's the old Windows-only 5.1 version that doesn't exist on macOS).

### Step 3 — PAC CLI (Power Platform CLI)

> **npm gotcha:** The PAC CLI is NOT an npm package. `npm install -g @microsoft/powerplatform-cli` returns 404. It is a .NET global tool.

> **DOTNET_ROOT gotcha:** Homebrew installs .NET to a non-standard path that PAC CLI can't find automatically. You must set `DOTNET_ROOT` in your shell profile, or `pac` will error with "You must install .NET to run this application."

Install PAC CLI:
```bash
dotnet tool install --global Microsoft.PowerApps.CLI.Tool
```

Add the required environment variables to `~/.zshrc`:
```bash
echo '' >> ~/.zshrc
echo '# PAC CLI (Power Platform) — required for Nexus automation scripts' >> ~/.zshrc
echo 'export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"' >> ~/.zshrc
echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zshrc
```

Apply in the current session:
```bash
source ~/.zshrc
```

Verify:
```bash
pac help
# Microsoft PowerPlatform CLI
# Version: 2.7.4+...
```

> **pac --version gotcha:** `pac --version` returns an error. Use `pac help` to confirm PAC CLI is working. This is normal behavior for PAC CLI — it doesn't support `--version` as a standalone flag.

### Step 4 — PowerShell Modules

Open `pwsh` (not bash) and run:

```powershell
# Microsoft Graph — large download (~300MB), allow 3-5 minutes
Install-Module Microsoft.Graph -Scope CurrentUser -Force -AcceptLicense

# Power Platform admin + user modules
Install-Module Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser -Force -AcceptLicense
Install-Module Microsoft.PowerApps.PowerShell -Scope CurrentUser -Force -AcceptLicense

# SSH for CloudFS (used only for CloudFS 8.5.x audit settings)
Install-Module Posh-SSH -Scope CurrentUser -Force -AcceptLicense
```

Verify:
```powershell
Get-Module -ListAvailable Microsoft.Graph, Microsoft.PowerApps*, Posh-SSH |
    Select-Object Name, Version | Sort-Object Name -Unique
```

Expected output:
```
Name                                          Version
----                                          -------
Microsoft.Graph                               2.36.1
Microsoft.PowerApps.Administration.PowerShell 2.0.217
Microsoft.PowerApps.PowerShell                1.0.45
Posh-SSH                                      3.2.7
```

---

## Architecture Notes (Apple Silicon)

All tools installed here are native arm64 binaries via Homebrew's Apple Silicon path (`/opt/homebrew`). Do not mix with Rosetta-translated tools if you can avoid it.

- Homebrew on Apple Silicon installs to `/opt/homebrew/` (not `/usr/local/`)
- .NET 10 on Apple Silicon: `/opt/homebrew/opt/dotnet/libexec`
- PowerShell modules install to: `~/.local/share/powershell/Modules/`
- .NET global tools install to: `~/.dotnet/tools/`

---

## Shell Profile Summary

After setup, your `~/.zshrc` will contain these additions:

```zsh
# PAC CLI (Power Platform) — required for Nexus automation scripts
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
export PATH="$PATH:$HOME/.dotnet/tools"
```

You only need to run `source ~/.zshrc` once per session if you just added these. New terminal windows pick them up automatically.

---

## Troubleshooting

**`pwsh: command not found`**
Homebrew may not be on your PATH. Run: `eval "$(/opt/homebrew/bin/brew shellenv)"` then retry.

**`pac: command not found`**
`$HOME/.dotnet/tools` is not on your PATH. Run `source ~/.zshrc` or open a new terminal.

**`pac` error: "You must install .NET to run this application"**
`DOTNET_ROOT` is not set. Run: `export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"` then retry.

**`Install-Module` errors about NuGet or PSGallery**
Run this first in pwsh: `Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force`

**Microsoft.Graph install takes forever / seems stuck**
It's a large module (~300MB, ~40 sub-packages). Give it 5 minutes. If it fails, re-run with `-Verbose` to see progress.

**`Connect-MgGraph` prompts for browser auth even with client credentials**
This is correct behavior on first run. Interactive login is needed for the pre-flight script until the app is registered. Subsequent scripts use client credential flow.

---

## What Each Tool Is Used For

| Tool | Used in |
|---|---|
| `pwsh` | Running all `.ps1` scripts in this project |
| `Microsoft.Graph` | `scripts/entra/` — app registration, permissions, Graph API calls |
| `Microsoft.PowerApps.Administration.PowerShell` | `scripts/power-platform/` — PPAC operations (Path B, low priority) |
| `Microsoft.PowerApps.PowerShell` | `scripts/copilot/` — connector and environment operations |
| `Posh-SSH` | `scripts/cloudfs/` — SSH to CloudFS 8.5.x nodes only |
| `pac` (PAC CLI) | `scripts/copilot/` — create custom connector, agent, publish |
