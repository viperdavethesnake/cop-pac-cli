# Prerequisites — What You Need and When

You do not need everything upfront. The deployment is staged — start with your Tenant ID
and the scripts populate everything else as you go.

---

## Day 1 — The only things you fill in manually

```
ENTRA_APP_NAME      default: Panzura-Nexus      (shows in Entra portal)
CONNECTOR_NAME      default: Panzura Nexus       (shows in Power Apps)
ENTRA_TENANT_ID     your tenant GUID
```

`ENTRA_APP_NAME` and `CONNECTOR_NAME` are pre-filled with Panzura defaults — change them
if you want custom branding before running anything. They cannot be renamed after `entra/01` runs.

`ENTRA_TENANT_ID` is at: `portal.azure.com → Entra ID → Overview → Directory (tenant) ID`

Put all three in `.env` then run `scripts/entra/00-Validate-Prerequisites.ps1`.
Everything else in Stage 1 is written by the scripts.

---

## Stage 1 — Entra ID  (scripts write these, you don't)

Scripts `entra/01` through `entra/03` write these back to `.env` automatically.
You need **Global Administrator** or **Application Administrator** role in Entra ID.

| Value | Written by | .env key |
|---|---|---|
| Client ID | `entra/01-Register-NexusApp.ps1` | `ENTRA_CLIENT_ID` |
| Client Secret | `entra/03-New-ClientSecret.ps1` | `ENTRA_CLIENT_SECRET` |

**Note on the browser popup:** The entra scripts use interactive (delegated admin) login.
The browser opens once. After that, MSAL caches the token and subsequent scripts authenticate
silently — no additional popups within the same day.

---

## Stage 2 — Nexus Host  (fill in when the VM is deployed)

Nexus must be running and reachable on port 443 before running `scripts/nexus/`.

| Value | Where it comes from | .env key |
|---|---|---|
| IP address | Azure Portal / Hyper-V Manager | `NEXUS_IP` |
| Admin username | Set during Nexus setup wizard | `NEXUS_ADMIN_USER` |
| Admin password | Set during Nexus setup wizard | `NEXUS_ADMIN_PASSWORD` |
| License key | Panzura Support or Sales | `NEXUS_LICENSE_KEY` |

**SSL note:** Nexus uses a self-signed certificate by default. Set `NEXUS_SKIP_SSL_VERIFY=true`
in `.env` for lab environments. For production, trust the cert in the system keychain.

---

## Stage 3 — CloudFS  (fill in when the CloudFS ring is running)

Target version: **CloudFS 8.7.0**.

| Value | Where it comes from | .env key |
|---|---|---|
| Master node FQDN or IP | CloudFS administrator | `CLOUDFS_MASTER_NODE` |
| Admin username | CloudFS administrator | `CLOUDFS_ADMIN_USER` |
| Admin password | CloudFS administrator | `CLOUDFS_ADMIN_PASSWORD` |
| SMB node FQDN or IP | CloudFS administrator | `CLOUDFS_SMB_NODE` |
| SMB username | CloudFS administrator | `CLOUDFS_SMB_USER` |
| SMB password | CloudFS administrator | `CLOUDFS_SMB_PASSWORD` |
| Domain | AD domain where CloudFS is joined | `CLOUDFS_DOMAIN` |

**SMB node:** Use a low-utilization subordinate or dedicated node — not the master.
For cloud-deployed CloudFS, use a cloud node to minimize egress costs.

**SMB user permissions:** Needs global read-only access to the CloudFS filesystem at minimum.
These credentials are stored in Nexus for continuous scanning.

---

## Stage 4 — Active Directory  (fill in when AD details are available)

| Value | Where it comes from | .env key |
|---|---|---|
| AD server hostname or IP | AD administrator | `AD_HOST` |
| Domain FQDN | AD administrator | `AD_DOMAIN` |
| Bind username | AD administrator | `AD_BIND_USER` |
| Bind password | AD administrator | `AD_BIND_PASSWORD` |

**Bind user permissions:** Read-only access to users and groups is sufficient. Domain Admin
is not needed.

**Entra Connect V2 requirement:** On-prem AD must be syncing to Entra ID via Microsoft Entra
Connect V2 before Nexus identity mapping will work correctly. Verify in Entra portal that
users show `onPremisesSyncEnabled = true`. The pre-flight script checks this.

---

## Stage 5 — Nexus Plugin IDs  (scripts write these, you don't)

Scripts `nexus/01` through `nexus/06` write these back to `.env` automatically.

| Value | Written by | .env key |
|---|---|---|
| Storage Plugin ID | `nexus/01-Configure-StoragePlugin.ps1` | `NEXUS_STORAGE_PLUGIN_ID` |
| AI Plugin ID | `nexus/02-Configure-AiPlugin.ps1` | `NEXUS_AI_PLUGIN_ID` |
| IAM Plugin ID | `nexus/03-Configure-IamPlugin.ps1` | `NEXUS_IAM_PLUGIN_ID` |
| Policy ID | `nexus/05-Configure-Policy.ps1` | `NEXUS_POLICY_ID` |
| AI Connector ID | `nexus/06-Activate-Policy.ps1` | `NEXUS_AI_CONNECTOR_ID` |

`NEXUS_AI_CONNECTOR_ID` is the most important — it becomes the `contentSource` for the
Copilot agent: `/external/connections/<NEXUS_AI_CONNECTOR_ID>`

---

## Stage 6 — Power Platform  (fill in before copilot/01)

Only needed for the custom connector step. Find these in the Power Platform Admin Center
(`admin.powerplatform.microsoft.com`).

| Value | Where it comes from | .env key |
|---|---|---|
| Environment URL | PPAC → Environments → select env → copy URL | `PPAC_ENVIRONMENT_URL` |

If `PPAC_ENVIRONMENT_URL` is not set, `copilot/01` uses the active `pac auth` profile.

---

## Access Roles Summary

| System | Required Role |
|---|---|
| Microsoft Entra ID | Global Administrator or Application Administrator |
| Microsoft 365 Admin Center | Global Administrator (for agent approval in copilot/03) |
| Power Platform | System Administrator on the target environment |
| Copilot Studio | Agent Author or higher |
| Azure Portal | Contributor or Owner (if deploying Nexus VM to Azure) |
| CloudFS | Administrator credentials for master + SMB nodes |
| Active Directory | Domain user with read access to users and groups |
| Nexus | Admin credentials (created during Nexus setup wizard) |
