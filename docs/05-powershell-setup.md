# PowerShell + Toolchain Setup

> **This doc is superseded by [`setup/README.md`](../setup/README.md).**
> That file is the maintained, tested reference for macOS Apple Silicon setup.
> Read it instead of this one.

---

## Quick Reference (macOS Apple Silicon)

```bash
bash setup/01-Install-Homebrew-Tools.sh   # PowerShell, .NET, PAC CLI
pwsh setup/02-Install-PSModules.ps1       # Microsoft.Graph and other PS modules
pwsh setup/03-Verify-Setup.ps1            # Verify everything before running scripts
```

---

## Known Gotchas (documented in setup/README.md)

These are the four issues discovered during actual setup on Apple Silicon — all fixed in
the setup scripts, documented here for reference:

| Symptom | Wrong approach | Correct approach |
|---|---|---|
| PowerShell install fails | `brew install --cask powershell` | `brew install powershell` (formula, not cask) |
| PAC CLI install fails | `npm install -g @microsoft/powerplatform-cli` | `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` |
| `pac` not found after install | Missing PATH entry | Add `$HOME/.dotnet/tools` to PATH in `~/.zshrc` |
| `pac` errors about .NET | Missing DOTNET_ROOT | Set `DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec` in `~/.zshrc` |

---

## Authentication Behavior

**`entra/` scripts — interactive (browser popup):**
The entra scripts use delegated admin authentication because granting admin consent requires
a human admin to personally authorize the operation. The Microsoft Graph PowerShell SDK uses
MSAL, which caches tokens to disk (`~/.local/share/microsoft/powershell/`).

- First run: browser popup, sign in as Global Administrator
- Subsequent runs the same day: silent — MSAL refreshes the token without a browser
- New day or expired token: one more browser popup, then silent again

**All other scripts — service principal (no browser):**
Once `ENTRA_CLIENT_ID` and `ENTRA_CLIENT_SECRET` are in `.env` (after `entra/03`), all
remaining scripts use `_common/Connect-Graph.ps1`, which authenticates via client credentials
flow. No browser, no user interaction, ever.

---

## .env Pattern

PowerShell has no built-in `.env` support. This project uses `scripts/_common/Config.ps1`
to load `.env` from the project root into `$env:` variables.

Each script declares what it needs before sourcing Config.ps1:

```powershell
$script:RequiredVars = @('ENTRA_TENANT_ID', 'ENTRA_CLIENT_ID')
. "$PSScriptRoot/../_common/Config.ps1"
# Now $env:ENTRA_TENANT_ID and $env:ENTRA_CLIENT_ID are set and validated
```

Scripts also write generated values back to `.env` using `Set-EnvValue`:

```powershell
Set-EnvValue 'ENTRA_CLIENT_ID' $app.AppId
# Updates .env in place and sets $env:ENTRA_CLIENT_ID for the current session
```

---

## Execution Policy (Windows only)

If running on Windows and scripts are blocked:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

On macOS there is no execution policy restriction.
