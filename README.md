# Panzura Nexus — Automation Scripts

PowerShell automation for the end-to-end Nexus 1.0.0 deployment and integration stack:
**CloudFS → Nexus → Microsoft Graph Connector → Microsoft 365 Copilot → Copilot Studio Agent**

---

## Start Here

**You need one thing to begin: your Entra Tenant ID.**

```
portal.azure.com → Entra ID → Overview → Directory (tenant) ID
```

Everything else — Client ID, Client Secret, plugin IDs, connector ID — is written to `.env`
automatically as you run scripts in order. You fill in infrastructure credentials (Nexus IP,
CloudFS, AD) as that infrastructure becomes available.

---

## Environment Setup (macOS Apple Silicon)

Run these once before anything else. See [`setup/README.md`](setup/README.md) for the full
guide including Apple Silicon gotchas and troubleshooting.

```bash
# 1. Install Homebrew, PowerShell, .NET, PAC CLI  (bash)
bash setup/01-Install-Homebrew-Tools.sh

# 2. Open a NEW terminal tab, then install PS modules
pwsh setup/02-Install-PSModules.ps1

# 3. Verify everything is green before continuing
pwsh setup/03-Verify-Setup.ps1
```

---

## Authentication

Two auth modes are used — scripts pick the right one automatically:

| Stage | Method | Browser? |
|---|---|---|
| `entra/` scripts | Interactive (delegated admin) | **Once** — MSAL caches the token. Subsequent runs are silent. |
| Everything else | Service principal (client credentials from `.env`) | Never |

The browser popup for the entra scripts happens **one time**. After that the token is cached on
disk and silently refreshed. Once `ENTRA_CLIENT_SECRET` is written to `.env` by `entra/03`,
all remaining scripts authenticate non-interactively.

---

## Run Sequence

```powershell
# ── Pre-flight: fix any FAILs before continuing ────────────────────────────────
pwsh scripts/entra/00-Validate-Prerequisites.ps1

# ── Stage 1: Entra ID app registration ────────────────────────────────────────
# Only ENTRA_TENANT_ID needs to be in .env before this stage.
# Each script writes its outputs back to .env automatically.

pwsh scripts/entra/01-Register-NexusApp.ps1        # → writes ENTRA_CLIENT_ID
pwsh scripts/entra/02-Set-ApiPermissions.ps1       # → adds 11 Graph permissions + grants admin consent
pwsh scripts/entra/03-New-ClientSecret.ps1         # → writes ENTRA_CLIENT_SECRET

# ── Stage 2: CloudFS audit settings ───────────────────────────────────────────
# 8.7.0 is UI-only — script prints exact steps node by node.
pwsh scripts/cloudfs/01-Enable-AuditSettings.ps1

# ── Stage 3: Nexus web UI configuration ───────────────────────────────────────
# Fill in Stage 2-4 .env values (Nexus IP, CloudFS, AD) before this stage.
# Each script writes its plugin/policy ID back to .env automatically.

pwsh scripts/nexus/01-Configure-StoragePlugin.ps1  # → writes NEXUS_STORAGE_PLUGIN_ID
pwsh scripts/nexus/02-Configure-AiPlugin.ps1       # → writes NEXUS_AI_PLUGIN_ID
pwsh scripts/nexus/03-Configure-IamPlugin.ps1      # → writes NEXUS_IAM_PLUGIN_ID
pwsh scripts/nexus/04-Configure-Rules.ps1
pwsh scripts/nexus/05-Configure-Policy.ps1         # → writes NEXUS_POLICY_ID
pwsh scripts/nexus/06-Activate-Policy.ps1          # → writes NEXUS_AI_CONNECTOR_ID

# ── Stage 4: Microsoft 365 ────────────────────────────────────────────────────
pwsh scripts/m365/02-Assign-CopilotLicenses.ps1    # verify/assign Copilot licenses
pwsh scripts/m365/03-Verify-ConnectorIngestion.ps1 # wait for connector state = ready
pwsh scripts/m365/01-Enable-ConnectorForCopilot.ps1 # "Give visibility to Copilot"

# ── Stage 5: Copilot Studio ───────────────────────────────────────────────────
pwsh scripts/copilot/01-New-CustomConnector.ps1    # creates Power Apps connector via PAC CLI
pwsh scripts/copilot/02-New-CopilotAgent.ps1       # guided walkthrough in Copilot Studio UI
pwsh scripts/copilot/03-Publish-Agent.ps1          # guided publish + admin approval
```

---

## What's Automated vs Manual

| Script | Automated | Manual |
|---|---|---|
| `entra/00` | Validates all prerequisites | Fix any FAILs it reports |
| `entra/01` | Registers app, writes CLIENT_ID | Browser login (once) |
| `entra/02` | Adds 11 permissions, grants admin consent | Browser login (cached) |
| `entra/03` | Creates secret, writes CLIENT_SECRET | Browser login (cached) |
| `nexus/01–05` | Configures plugins + policy via REST API | Fill in Stage 2–4 .env values |
| `nexus/06` | Activates policy, writes CONNECTOR_ID | — |
| `m365/01` | Tries beta API PATCH | Falls back to portal steps if API fails |
| `m365/02` | Reports license availability | Assign licenses if needed |
| `m365/03` | Checks connector state + item count | — |
| `copilot/01` | Creates connector via PAC CLI, reads per-connector redirect URI from downloaded `apiProperties.json`, registers it with Entra app, runs smoke test (skipped until `NEXUS_AI_CONNECTOR_ID` set) | (1) Security tab: paste client secret, verify OBO field shows "true"; (2) Test tab → New Connection → Create; (3) Test tab → Test Operation; (4) Share tab: add users. Note: `CONNECTOR_NAME` must be ≤30 chars. |
| `copilot/02` | Prints all values and instructions | Copilot Studio UI (agent + tools) |
| `copilot/03` | Prints all steps | Copilot Studio + admin approval portal |
| `cloudfs/01` | Prints exact UI steps | CloudFS web UI (8.7.0 has no API) |
| `teardown/01` | Deletes connector, removes redirect URI, deletes + purges Entra app, clears .env | — |
| `inventory/01` | Snapshots all live resources to `inventory/inventory-YYYYMMDD-HHmmss.json` | — |

---

## Script Status

| Area | Scripts | Status |
|---|---|---|
| Pre-flight validation | `scripts/entra/00` | Complete |
| Entra ID app registration | `scripts/entra/01–03` | Complete |
| Nexus REST API configuration | `scripts/nexus/01–06` | Stubs — endpoints confirmed on live Nexus |
| M365 licensing + connector visibility | `scripts/m365/01–03` | Complete |
| Power Apps custom connector | `scripts/copilot/01` | Complete — tested 2026-05-11 |
| Copilot Studio agent | `scripts/copilot/02–03` | Guided walkthrough (UI workflow) |
| CloudFS audit settings | `scripts/cloudfs/01` | Guided walkthrough (8.7.0 UI-only) |
| Power Platform service principal | `scripts/power-platform/` | Low priority — Path B only |
| Azure VM deployment | `scripts/vm/azure/` | Documented, not scripted |
| Hyper-V VM deployment | `scripts/vm/hyperv/` | Documented, not scripted |
| Teardown (reverse all steps) | `scripts/teardown/01` | Complete — tested 2026-05-11 |
| Inventory snapshot | `scripts/inventory/01` | Complete — tested 2026-05-11 |

---

## Project Layout

```
nexus_scripts/
├── .env                           # Your secrets — gitignored, auto-populated by scripts
├── .env.example                   # Full reference with all keys and stage labels
├── setup/
│   ├── README.md                  # macOS setup guide with Apple Silicon gotchas
│   ├── 01-Install-Homebrew-Tools.sh
│   ├── 02-Install-PSModules.ps1
│   └── 03-Verify-Setup.ps1
├── docs/
│   ├── 00-admin-guide-breakdown.md   # Automation map + guide analysis
│   ├── 01-prerequisites.md           # Staged credential checklist
│   ├── 02-architecture.md            # How Nexus, Entra, CloudFS connect
│   ├── 03-vm-deployment-azure.md     # Azure VM steps (ready to script)
│   ├── 04-vm-deployment-hyperv.md    # Hyper-V steps (ready to script)
│   └── ms-reference/                 # Local snapshots of Microsoft Learn docs
├── artifacts/
│   ├── swagger/
│   │   └── nexus-connector-schema.yaml   # OpenAPI definition for Power Apps connector
│   └── agent/
│       └── agent-instructions.txt        # Copilot agent system prompt (verbatim from guide)
└── scripts/
    ├── _common/
    │   ├── Config.ps1                # Loads .env, validates required vars, Set-EnvValue
    │   ├── Connect-Graph.ps1         # Service principal Graph auth (non-interactive)
    │   └── Connect-PowerPlatform.ps1 # Power Platform auth helper
    ├── entra/                        # 00–03: app registration, permissions, secret
    ├── nexus/                        # 01–06: plugins, rules, policy, activation
    ├── m365/                         # 01–03: licenses, connector visibility, verification
    ├── copilot/                      # 01–03: connector, agent, publish
    ├── cloudfs/                      # 01: audit settings
    ├── power-platform/               # 01–02: service principal (Path B only)
    ├── teardown/                     # 01: reverse teardown of all deployed resources
    ├── inventory/                    # 01: live resource snapshot → timestamped JSON
    └── vm/                           # azure/ and hyperv/ — documented, not scripted
```

---

## Key Docs

| Doc | Purpose |
|---|---|
| [`setup/README.md`](setup/README.md) | How to install PowerShell, PAC CLI, modules on macOS |
| [`docs/01-prerequisites.md`](docs/01-prerequisites.md) | What credentials you need and when |
| [`docs/00-admin-guide-breakdown.md`](docs/00-admin-guide-breakdown.md) | Full automation map against the Nexus admin guide |
| [`docs/02-architecture.md`](docs/02-architecture.md) | How the components connect end to end |
| [`docs/ms-reference/README.md`](docs/ms-reference/README.md) | Index of local Microsoft API reference docs |

---

## Teardown and Inventory

```powershell
# Snapshot all live resources (Entra, Power Apps, Nexus, CloudFS, M365)
# Writes inventory/inventory-YYYYMMDD-HHmmss.json
pwsh scripts/inventory/01-Get-Inventory.ps1

# Reverse teardown — deletes connector, Entra app, clears .env
# Safe to run partially — each step checks existence before deleting
pwsh scripts/teardown/01-Teardown-All.ps1
```
