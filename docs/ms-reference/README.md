# Microsoft Reference Documentation

Local snapshots of Microsoft Learn pages covering every API and tool used in this project.
Fetched: 2026-05-05. Re-fetch periodically — Microsoft docs change frequently.

> **Re-fetch a file:** `pwsh -c "Invoke-WebRequest '<url>' -OutFile '<file>'"` or just re-run the agent that built this folder.

---

## Microsoft Graph — External Connectors (Nexus core integration)

| File | What it covers | Used by |
|---|---|---|
| [graph-connectors-overview.md](graph-connectors-overview.md) | How Graph Connectors work end-to-end — indexing, ACLs, schema, search | All nexus/ scripts |
| [graph-external-post-connections.md](graph-external-post-connections.md) | Create an ExternalConnection (the container Nexus registers) | nexus/05-06, reference |
| [graph-external-connection-update.md](graph-external-connection-update.md) | PATCH externalConnection — `enabledContentExperiences` for Copilot visibility (beta only) | m365/01 |
| [graph-external-connection-post-items.md](graph-external-connection-post-items.md) | Creating / updating ExternalItems (files indexed in Copilot) | nexus/05-06 |
| [graph-external-connection-post-schema.md](graph-external-connection-post-schema.md) | Defining the schema for an external connection (properties, labels) | nexus/05-06 |
| [graph-search-query-api.md](graph-search-query-api.md) | `/v1.0/search/query` — what the Copilot agent's SearchNexus tool calls | copilot/01, reference |

**Key concept:** When a Nexus policy activates, Nexus creates an `ExternalConnection` in Graph and pushes `ExternalItem` objects into it. This is the data Copilot searches.

---

## Microsoft Graph PowerShell SDK

| File | What it covers | Used by |
|---|---|---|
| [msgraph-powershell-get-started.md](msgraph-powershell-get-started.md) | Auth, Connect-MgGraph, basic patterns | scripts/_common/Connect-Graph.ps1 |
| [msgraph-new-mgapplication.md](msgraph-new-mgapplication.md) | `New-MgApplication` — full parameter reference | scripts/entra/01 |
| [msgraph-add-mgapplicationpassword.md](msgraph-add-mgapplicationpassword.md) | `Add-MgApplicationPassword` — create client secrets | scripts/entra/03 |
| [msgraph-new-mgserviceprincipalapproleassignment.md](msgraph-new-mgserviceprincipalapproleassignment.md) | `New-MgServicePrincipalAppRoleAssignment` — grant application permissions (admin consent) | scripts/entra/02 |
| [msgraph-new-mgoauth2permissiongrant.md](msgraph-new-mgoauth2permissiongrant.md) | `New-MgOauth2PermissionGrant` — grant delegated permissions (admin consent) | scripts/entra/02 |
| [graph-application-update.md](graph-application-update.md) | `Update-MgApplication` — modify app properties, RequiredResourceAccess, redirect URIs | scripts/entra/02, copilot/01 |

**Module install:** `Install-Module Microsoft.Graph -Scope CurrentUser`

---

## Power Platform

| File | What it covers | Used by |
|---|---|---|
| [ppac-manage-application-users.md](ppac-manage-application-users.md) | Create app users in PPAC, assign security roles (System Administrator) | scripts/power-platform/01-02 |

**Module install:** `Install-Module Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser`

---

## Copilot Studio

| File | What it covers | Used by |
|---|---|---|
| [copilot-studio-publish.md](copilot-studio-publish.md) | Publishing agents to channels (Teams, M365 Copilot), availability options | scripts/copilot/03 |

---

## Power Apps / Custom Connectors

| File | What it covers | Used by |
|---|---|---|
| [power-apps-custom-connector-blank.md](power-apps-custom-connector-blank.md) | Building a custom connector from scratch — General, Security, Definition, Code, Test tabs | scripts/copilot/01 |
| [pac-cli-connector.md](pac-cli-connector.md) | PAC CLI `connector` command group — create, update, download, list | scripts/copilot/01 |

The swagger definition for our connector is in `artifacts/swagger/nexus-connector-schema.yaml`.

---

## Entra Connect / Hybrid Identity

| File | What it covers | Used by |
|---|---|---|
| [entra-connect-v2-overview.md](entra-connect-v2-overview.md) | What Entra Connect V2 is, sync architecture, prerequisites | docs/01-prerequisites.md reference |

**Note:** Entra Connect V2 must be running and syncing before Nexus identity mapping works. Installation is a prerequisite, not automated by these scripts.

---

## Microsoft 365 Copilot

| File | What it covers | Used by |
|---|---|---|
| [m365-copilot-setup.md](m365-copilot-setup.md) | Licensing, enabling Copilot, admin prerequisites | Reference / prerequisites |

---

## Still Needed — Fetch Manually or Next Session

These pages were identified as useful but not yet downloaded:

| Topic | URL |
|---|---|
| PAC CLI copilot / agent commands | https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/copilot |
| Graph connector admin consent flow | https://learn.microsoft.com/en-us/graph/connecting-external-content-connectors-api-postman |
| `New-MgServicePrincipal` cmdlet | https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.applications/new-mgserviceprincipal |

---

## Notes on 404s

Three of the original URLs 404'd — the docs were at different canonical paths:

| Original URL (404) | Actual content saved from |
|---|---|
| `.../externalconnectors-externalconnection-post-items` | `connecting-external-content-manage-items` |
| `.../externalconnectors-externalconnection-post-schema` | `connecting-external-content-manage-schema` |
| `.../microsoft-365/admin/misc/microsoft-365-copilot-setup` | `.../microsoft-365/copilot/microsoft-365-copilot-setup` |
| `.../microsoft-copilot-studio/publish-copilot-flow` | `.../microsoft-copilot-studio/publication-fundamentals-publish-channels` |
