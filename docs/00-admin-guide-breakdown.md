# Admin Guide Breakdown — Automation Map

Source: `Nexus1.0.0AdminGuide.pdf` (Nexus 1.0.0, Panzura 2026)

## What Nexus Does

Panzura Nexus is an integration layer that connects **CloudFS** (unstructured enterprise file storage) to **Microsoft 365 Copilot** via a Microsoft Graph Connector. It ingests file content, metadata, and ACLs so Copilot can answer natural-language queries while honoring the original CloudFS permissions.

```
CloudFS (files + ACLs)
    └─► Nexus (policy engine, Graph Connector)
            └─► Microsoft 365 Copilot (AI search + chat)
                    └─► Copilot Studio Agent (conversational UI)
```

---

## Automation Phases

### Phase 1 — Entra ID App Registration (§2.10.2)
**All steps are fully automatable via Microsoft.Graph PowerShell module.**

| Guide Step | Script |
|---|---|
| Register new app in Entra ID | `scripts/entra/01-Register-NexusApp.ps1` |
| Add 10 API permissions to Microsoft Graph | `scripts/entra/02-Set-ApiPermissions.ps1` |
| Grant admin consent | `scripts/entra/02-Set-ApiPermissions.ps1` |
| Create client secret (max 2-year expiry) | `scripts/entra/03-New-ClientSecret.ps1` |

**Required Graph permissions for the Nexus app:**
```
Application:  AiEnterpriseInteraction.Read.All
              AppCatalog.ReadWrite.All
              Application.ReadWrite.All          ← NOT in admin guide §2.10.2 — required, add manually
              ExternalConnection.ReadWrite.All
              ExternalItem.ReadWrite.All
              Group.Read.All
              User.Read.All
Delegated:    ExternalItem.Read.All
              Files.Read.All
              Sites.Read.All
              User.Read
```

Outputs to capture: `$TenantId`, `$ClientId`, `$ClientSecret` → write to `.env`

---

### Phase 2 — Power Platform Service Principal (§2.10.5)
> **LOW PRIORITY — Path B only.** We are using Path A (manual Copilot Studio) for agent creation, so these scripts are not in the critical path. Kept for reference if Path B is needed later.

| Guide Step | Script |
|---|---|
| Log in to Power Platform Admin Center | `Connect-PowerPlatform.ps1` |
| Add app (Client ID) to default environment | `scripts/power-platform/01-Register-ServicePrincipal.ps1` |
| Assign System Administrator security role | `scripts/power-platform/02-Set-SystemAdminRole.ps1` |

**Why this exists:** Nexus uses this service principal to call Power Platform APIs during automated agent creation from its own web UI (§2.10.5 — "Path B"). Not needed for manual Copilot Studio workflow.

---

### Phase 3 — Nexus Web UI Configuration (§2.8, §2.10.1)
**Automatable via REST API against the Nexus host. Exact endpoints discovered via browser DevTools.**

| Guide Step | Script |
|---|---|
| Install license key | `scripts/nexus/01-Configure-StoragePlugin.ps1` (or standalone) |
| Configure Storage Plugin (CloudFS master + SMB) | `scripts/nexus/01-Configure-StoragePlugin.ps1` |
| Configure AI Plugin (Copilot — Tenant/Client/Secret) | `scripts/nexus/02-Configure-AiPlugin.ps1` |
| Configure IAM Plugin (on-prem AD) | `scripts/nexus/03-Configure-IamPlugin.ps1` |
| Create Rules (file extension, path, size filters) | `scripts/nexus/04-Configure-Rules.ps1` |
| Create Data Insight Policy (link plugins + rules) | `scripts/nexus/05-Configure-Policy.ps1` |
| Activate policy (triggers connector creation in M365) | `scripts/nexus/06-Activate-Policy.ps1` |

**After activation:** Nexus creates a Graph Connector in M365 named `<Panzura-Nexus-policy-id>`. This connector ID becomes `$NEXUS_AI_CONNECTOR_ID` needed by the Copilot agent's `contentSource`.

**Manual step remaining:** Log in to Microsoft cloud admin site, find connector named "Nexus", click "Give visibility to Copilot". (No API for this yet.)

---

### Phase 4 — Copilot Studio — Custom Connector (§2.10.4A)
**Automatable via PAC CLI + swagger file from `artifacts/swagger/`.**

| Guide Step | Script |
|---|---|
| Create connector from swagger definition | `scripts/copilot/01-New-CustomConnector.ps1` |
| Configure OAuth2 (Client ID, Secret, Tenant) | `scripts/copilot/01-New-CustomConnector.ps1` |
| Upload C# chunking script code | `scripts/copilot/01-New-CustomConnector.ps1` |
| Add redirect URI back to Entra app | `scripts/entra/01-Register-NexusApp.ps1` (update step) |
| Test connector (200 response) | Manual — requires browser session |
| Share connector | `scripts/copilot/01-New-CustomConnector.ps1` |

**Tool:** `pac connector create` from Power Platform CLI

---

### Phase 5 — Copilot Studio — Agent (§2.10.4B–D) — PATH A
**Using manual Copilot Studio workflow (NOT Nexus web UI wizard).**
Script validates prerequisites, prints the exact contentSource value, outputs agent instructions ready to paste, and walks through each tool configuration step.

| Guide Step | Automation |
|---|---|
| Create blank agent | `pac copilot create` (PAC CLI — being confirmed) or manual in Studio |
| Set name, model (GPT-5 Reasoning), instructions | Script outputs instructions to paste; UI steps manual |
| Add SearchNexus tool + contentSource input | Script prints exact value; wiring is manual in Studio |
| Add GetExternalItem tool + chunkSize=60000 | Script prints values; wiring is manual in Studio |
| Publish to Teams + M365 Copilot channel | `scripts/copilot/03-Publish-Agent.ps1` (PAC CLI) |
| Admin approval (admin.cloud.microsoft.com) | Manual — M365 admin portal, no public API |

**Script:** `scripts/copilot/02-New-CopilotAgent.ps1` — run it, follow its output step by step in the browser.

---

### Phase 6 — CloudFS Audit Settings (§2.3.3)
**Target version: 8.7.0 — UI-only, no SSH CLI available.**
The script prints a precise step-by-step guide and validates the node is reachable. SSH automation code is retained for future 8.5.x use.

| CloudFS Version | Automation | Script |
|---|---|---|
| **8.7.0 (current target)** | Manual UI — script prints steps | `scripts/cloudfs/01-Enable-AuditSettings.ps1` |
| 8.6.x | Manual UI — same as 8.7.0 | same script, same branch |
| 8.5.x (legacy) | SSH automation | same script, SSH branch |

---

### Phase 3.5 — Microsoft 365 Admin (between Nexus activation and Copilot agent)

These three steps happen AFTER Nexus activates the policy and BEFORE the Copilot agent is useful.

| Step | Script | Notes |
|---|---|---|
| Verify M365 Copilot licenses assigned | `scripts/m365/02-Assign-CopilotLicenses.ps1` | Reports availability; optional assignment |
| Verify connector is indexing (state = ready) | `scripts/m365/03-Verify-ConnectorIngestion.ps1` | Polls Graph API for connector state + item count |
| Enable connector for Copilot | `scripts/m365/01-Enable-ConnectorForCopilot.ps1` | Tries beta PATCH; falls back to manual portal steps |

**API status for connector visibility:** `enabledContentExperiences` exists in beta API only. Enum value `copilotSearch` is undocumented but functional. v1.0 does not expose this property. Script tries beta PATCH first; if it fails, prints exact portal steps. See `docs/ms-reference/graph-external-connection-update.md`.

---

### Deferred — VM Deployment

Documented and ready to script, but out of scope for now.

| Area | Doc |
|---|---|
| Azure VM (VHD upload, image, VM, NSG, disk) | `docs/03-vm-deployment-azure.md` |
| Hyper-V VM (VHDX extract, VM create, BIOS, disk) | `docs/04-vm-deployment-hyperv.md` |

---

## End-to-End Credential Flow

```
Entra App Registration
    ├── TenantId   ──────────────► Nexus AI Plugin config
    ├── ClientId   ──────────────► Nexus AI Plugin config
    │                              Power Platform app user
    │                              Copilot connector OAuth2
    └── ClientSecret ────────────► Nexus AI Plugin config
                                   Copilot connector OAuth2

Nexus Policy Activation
    └── AI Connector ID ─────────► Copilot agent contentSource input

CloudFS
    ├── Master node FQDN/IP ─────► Nexus Storage Plugin
    ├── Admin user/password ─────► Nexus Storage Plugin
    ├── SMB node FQDN/IP ────────► Nexus Storage Plugin
    └── SMB user/password ───────► Nexus Storage Plugin

Active Directory
    ├── AD Host ─────────────────► Nexus IAM Plugin
    ├── Domain ──────────────────► Nexus IAM Plugin
    └── Bind user/password ──────► Nexus IAM Plugin
```
