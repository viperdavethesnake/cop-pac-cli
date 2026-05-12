# Nexus Automation — Resume File

Last updated: 2026-05-11

Use this file to orient any new session. Read TODO.md for the full task list.

---

## What This Project Is

PowerShell automation for the end-to-end Panzura Nexus 1.0.0 deployment:

```
CloudFS → Nexus REST API → Microsoft Graph Connector → M365 Copilot → Copilot Studio Agent
```

Owner: David Barley (david.barley@panzura.com), Panzura  
Working directory: `/Users/dmbarley/claude/`

---

## Current Project State

### What Is Complete and Ready to Test

| Area | Scripts | State |
|---|---|---|
| Pre-flight validation | `entra/00` | Complete — can run against real tenant now |
| Entra app registration | `entra/01` | Complete — can run against real tenant now |
| API permissions (11) | `entra/02` | Complete — can run against real tenant now |
| Client secret | `entra/03` | Complete — can run against real tenant now |
| Graph connector visibility | `m365/01` | Complete — run after nexus/06 |
| Copilot license report | `m365/02` | Complete |
| Connector health check | `m365/03` | Complete — run after nexus/06 |
| Custom connector (PAC CLI) | `copilot/01` | Complete — **tested live 2026-05-11** |
| Copilot Studio agent guide | `copilot/02` | Complete — guided UI walkthrough |
| Publish + admin approval | `copilot/03` | Complete — guided UI walkthrough |
| CloudFS audit settings | `cloudfs/01` | Complete — guided UI walkthrough |
| macOS toolchain | `setup/01–03` | Complete — verified working |

### What Is Blocked (Needs Infrastructure)

| Area | Scripts | Blocker |
|---|---|---|
| Nexus REST API config | `nexus/01–06` | Nexus VM not deployed — endpoints are stubs |

The nexus scripts have full structure, `Set-EnvValue` wiring, and all `.env` keys mapped.
They are missing only the actual REST endpoint paths (URLs to confirm via browser DevTools on live Nexus).

---

## Key Design Decisions (Do Not Revisit Without Good Reason)

**`.env` auto-population** — Scripts use `Set-EnvValue` (defined in `_common/Config.ps1`) to write their outputs back to `.env` in-place. No manual copy-paste. The function uses `$PSScriptRoot` (resolves to `_common/`) so `../../.env` always finds project root regardless of calling script location.

**`$script:RequiredVars` pattern** — Each script declares which env vars it needs *before* dot-sourcing `Config.ps1`. Config only validates those vars, so scripts don't fail on keys they don't use yet.

**11 API permissions, not 10** — Admin guide §2.10.2 lists 10 permissions. We added `Application.ReadWrite.All` (Application type) as the 11th. It is required for `copilot/01` to update the Entra app's redirect URIs. This is intentional and correct.

**Two auth modes, no mixing**
- `entra/` scripts: Interactive delegated login (`Connect-MgGraph -Scopes`). Browser opens once, MSAL caches token to disk, subsequent runs that day are silent.
- All other scripts: Service principal (`Connect-Graph.ps1`), never a browser. Requires `ENTRA_CLIENT_SECRET` in `.env` (written by `entra/03`).

**PAC CLI = dotnet tool, not npm** — `dotnet tool install --global Microsoft.PowerApps.CLI.Tool`. On Apple Silicon, requires `DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec`. `pac --version` doesn't work — use `pac help` to verify install. See `setup/README.md`.

**Client secret NOT in PAC CLI call** — Power Platform custom connectors don't accept client secrets via CLI. The secret is entered manually in the Power Apps portal Security tab after `pac connector create` runs. `copilot/01` prints the secret value and exact portal steps.

**Per-connector redirect URI** — Power Platform generates a unique redirect URI per connector (`https://global.consent.azure-apim.net/redirect/<connector-unique-name>`). `copilot/01` downloads the connector post-create, reads the actual `redirectUrl` from `apiProperties.json`, and registers it with the Entra app. The old generic redirect URI no longer works.

**`CONNECTOR_NAME` max 30 chars** — Power Platform enforces a 30-character limit on the OpenAPI `info.title`. `copilot/01` patches the title from `.env`. Keep `CONNECTOR_NAME` ≤30 chars.

**`copilot/02` is UI-only** — `pac copilot create` does not exist. Copilot Studio agent creation has no CLI interface. The script is a guided walkthrough — all steps happen in the browser.

**Connector name format** — When Nexus activates a policy, it creates a Graph ExternalConnection named `<ENTRA_APP_NAME>-<policy-id>`. Both names come from `.env`. Do not hardcode `Panzura-Nexus` anywhere.

**`enabledContentExperiences`** — Beta API only. Enum value `copilotSearch` is undocumented but functional. `m365/01` tries the PATCH, falls back to manual portal steps if it fails. See `docs/ms-reference/graph-external-connection-update.md`.

---

## Recommended Test Sequence (No Infrastructure Needed)

These can be tested right now against the real Entra tenant:

```powershell
# 1. Verify toolchain
pwsh setup/03-Verify-Setup.ps1

# 2. Pre-flight (needs ENTRA_TENANT_ID in .env)
pwsh scripts/entra/00-Validate-Prerequisites.ps1

# 3. Register app (browser popup once)
pwsh scripts/entra/01-Register-NexusApp.ps1   # writes ENTRA_CLIENT_ID to .env

# 4. Set 11 permissions + admin consent
pwsh scripts/entra/02-Set-ApiPermissions.ps1

# 5. Create client secret
pwsh scripts/entra/03-New-ClientSecret.ps1    # writes ENTRA_CLIENT_SECRET to .env

# 6. Verify in Entra portal:
#    - App registration exists with name from ENTRA_APP_NAME
#    - 11 permissions shown + "Granted" status for all
#    - Client secret listed under Certificates & secrets
```

After `entra/03`, run `copilot/01` (Power Platform environment required, PPAC_ENVIRONMENT_URL in .env):
```powershell
pwsh scripts/copilot/01-New-CustomConnector.ps1
# Creates connector, auto-detects per-connector redirect URI, adds to Entra app
# Then complete 4 manual steps: Security tab (paste secret), New Connection, Test Operation, Share
```

**`copilot/01` notes (from live test 2026-05-11):**
- `CONNECTOR_NAME` must be ≤30 characters (Power Platform limit)
- Script patches swagger `info.title` from `.env` CONNECTOR_NAME — do not rely on the swagger file's title
- Per-connector redirect URI is read from `apiProperties.json` after creation — the old generic `https://global.consent.azure-apim.net/redirect` no longer works
- Smoke test skips Graph Search until `NEXUS_AI_CONNECTOR_ID` is set (driveItem search requires delegated auth; externalItem is tested once Nexus is connected)

---

## Open Work — Priority Order

See `TODO.md` for the full list. Top items:

1. **Nexus endpoint discovery** — Blocked. Capture actual REST endpoints via browser DevTools on live Nexus. Replace all `# TODO: Confirm endpoint path` comments in `nexus/01–06`.

2. **Connect-Nexus helper** — When Nexus is deployed, extract the repeated auth block from `nexus/01–06` into `_common/Connect-Nexus.ps1`.

3. **Rule ID → Policy wiring** — `nexus/04` creates rules but `nexus/05` uses `ruleIds = @()` (empty). Fix: `nexus/04` writes rule IDs to `.env` as `NEXUS_RULE_IDS`, `nexus/05` reads them.

4. **Policy activation polling** — `nexus/06` reads `aiConnectorId` immediately after activation, but connector creation is async. Needs a retry loop (poll every 15s, max 5 min).

---

## `.env` Key Map

```
# Stage 1 — fill before entra/00
ENTRA_APP_NAME          default: Panzura-Nexus
CONNECTOR_NAME          default: Panzura Nexus
ENTRA_TENANT_ID         fill manually (portal.azure.com → Entra ID → Overview)

# Stage 1 — written by entra/01 and entra/03
ENTRA_CLIENT_ID         ← entra/01
ENTRA_CLIENT_SECRET     ← entra/03

# Stage 2 — fill when Nexus VM is deployed
NEXUS_IP
NEXUS_ADMIN_USER        default: admin
NEXUS_ADMIN_PASSWORD
NEXUS_LICENSE_KEY
NEXUS_SKIP_SSL_VERIFY   default: true (lab)

# Stage 3 — fill when CloudFS is running
CLOUDFS_MASTER_NODE
CLOUDFS_ADMIN_USER
CLOUDFS_ADMIN_PASSWORD
CLOUDFS_SMB_NODE
CLOUDFS_SMB_USER
CLOUDFS_SMB_PASSWORD
CLOUDFS_DOMAIN

# Stage 4 — fill when AD details available
AD_HOST
AD_DOMAIN
AD_BIND_USER
AD_BIND_PASSWORD

# Stage 5 — written by nexus/01–06
NEXUS_STORAGE_PLUGIN_ID ← nexus/01
NEXUS_AI_PLUGIN_ID      ← nexus/02
NEXUS_IAM_PLUGIN_ID     ← nexus/03
NEXUS_POLICY_ID         ← nexus/05
NEXUS_AI_CONNECTOR_ID   ← nexus/06  ← most important: becomes Graph contentSource

# Stage 6 — written by copilot scripts
COPILOT_AGENT_NAME      default: Panzura Nexus Agent

# Stage 7 — fill before copilot/01 (or let pac auth profile handle it)
PPAC_ENVIRONMENT_URL
```

---

## File Layout (Key Files)

```
claude/  (working directory)
├── .env                              secrets, auto-populated by scripts, gitignored
├── .env.example                      full reference with stage labels
├── TODO.md                           prioritized task list
├── RESUME.md                         this file
├── README.md                         start-here guide + run sequence
├── setup/
│   ├── README.md                     macOS Apple Silicon setup guide
│   └── 01–03                         install + verify toolchain
├── docs/
│   ├── 00-admin-guide-breakdown.md   automation map vs Nexus admin guide
│   ├── 01-prerequisites.md           staged credential checklist
│   ├── 02-architecture.md            component diagram
│   └── ms-reference/                 local copies of Graph API docs
├── artifacts/
│   ├── swagger/nexus-connector-schema.yaml
│   └── agent/agent-instructions.txt
└── scripts/
    ├── _common/
    │   ├── Config.ps1                loads .env, validates vars, Set-EnvValue
    │   ├── Connect-Graph.ps1         service principal Graph auth
    │   └── Connect-PowerPlatform.ps1 Power Platform auth
    ├── entra/00–03                   COMPLETE
    ├── nexus/01–06                   STUBS (endpoints TBD)
    ├── m365/01–03                    COMPLETE
    ├── copilot/01–03                 COMPLETE
    ├── cloudfs/01                    COMPLETE (guided UI)
    └── power-platform/01–02          LOW PRIORITY — Path B only
```
