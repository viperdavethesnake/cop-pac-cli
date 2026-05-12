# Nexus Automation — TODO List

Last updated: 2026-05-11

---

## BLOCKED — Needs infrastructure

These cannot be done until Nexus and CloudFS VMs are deployed.

- [ ] **Discover Nexus REST endpoints** — Use browser DevTools (Network tab) on a live Nexus instance to capture actual API paths. Replace all `# TODO: Confirm endpoint path` comments in `scripts/nexus/01–06`.
  - Expected endpoints: `/api/auth/login`, `/api/license`, `/api/plugins/storage`, `/api/plugins/ai`, `/api/plugins/iam`, `/api/rules`, `/api/policies`, `/api/policies/{id}/activate`, `/api/policies/{id}`
  - Affected scripts: `nexus/01`, `02`, `03`, `04`, `05`, `06`

- [ ] **Fill Stage 2–4 in `.env`** — Nexus IP, admin credentials, CloudFS master + SMB nodes, AD host/domain/bind user. Cannot run `scripts/nexus/` until these are set.

- [x] **Test entra/00–03 end to end** — Tested live 2026-05-06. All passed. 4 bugs found and fixed (see project_entra_tested.md). Verify portal shows all 11 permissions granted.

- [x] **Test copilot/01** — Tested live 2026-05-11. Connector created, OAuth connection established, GetExternalItem HTTP 200. Three bugs found and fixed: (1) swagger `info.title` not patched with CONNECTOR_NAME → connector created with wrong display name; (2) Power Platform now uses per-connector redirect URI, not generic `global.consent.azure-apim.net/redirect` — script now downloads connector post-create and reads actual `redirectUrl` from `apiProperties.json`; (3) driveItem search fails with app-only auth (Microsoft limitation) — smoke test now skips until NEXUS_AI_CONNECTOR_ID is set.

---

## HIGH PRIORITY — Do when Nexus is deployed

- [ ] **Nexus auth helper** — Refactor the repeated auth block (login + token + headers) in `nexus/01–06` into `scripts/_common/Connect-Nexus.ps1`. All six scripts currently duplicate the same pattern.

- [ ] **Rule ID → Policy integration** — `nexus/04` creates rules but doesn't pass their IDs to `nexus/05`. Policy is created with `ruleIds = @()` (empty). Fix: write rule IDs to `.env` from `nexus/04`, read them in `nexus/05`.
  - Need a new `.env` key: `NEXUS_RULE_IDS` (comma-separated)

- [ ] **Policy activation polling** — `nexus/06` fetches the connector ID immediately after activation, but connector creation is async. Add a retry loop (poll every 15s, max 5 min) until `aiConnectorId` is populated in the policy response.

- [ ] **Verify AI Connector ID field name** — `nexus/06` assumes `$policy.aiConnectorId` is the field name. Confirm actual field name from live Nexus API response.

---

## MEDIUM PRIORITY — Quality of life improvements

- [ ] **Externalize ingestion rules** — `nexus/04` hardcodes one rule (`office-and-pdf`). Move to `artifacts/rules.json` so users can configure file extensions, paths, and size limits without editing scripts.

- [ ] **AD LDAP protocol/port** — `nexus/03` only configures FQDN + credentials. Add `AD_LDAP_PORT` (389 or 636) and `AD_PROTOCOL` (ldap/ldaps/ldaptls) to `.env` and wire into IAM plugin config. Ask Nexus DevTools what the field names are.

- [ ] **SMB connections configurable** — `nexus/01` hardcodes `smbConnections = 4`. Add `NEXUS_SMB_CONNECTIONS` to `.env` (optional, default 4).

- [ ] **Client secret expiry configurable** — `entra/03` hardcodes 365-day expiry. Add `ENTRA_SECRET_EXPIRY_DAYS` to `.env` (optional, default 365, max 730).

---

## LOW PRIORITY — Deferred

- [ ] **Power Platform service principal scripts** (`power-platform/01–02`) — Path B only (Nexus web UI agent creation). Not needed for our Path A workflow. Implement only if switching approaches.

- [ ] **VM deployment scripts** — Azure and Hyper-V deployment are documented in `docs/03` and `docs/04` but not scripted. Steps are straightforward; defer until needed.

- [x] **`copilot/01` — PAC CLI output parsing** — Confirmed working live 2026-05-11. GUID regex correctly extracts connector ID from `pac connector create` output. Used for post-create download to read redirect URI.

- [ ] **`m365/01` — Monitor beta API promotion** — The `enabledContentExperiences` property with `copilotSearch` is beta-only and undocumented. Watch for Microsoft to promote this to v1.0 or officially document the enum. See `docs/ms-reference/graph-external-connection-update.md`.

---

## DONE — Completed this session

- [x] `.env` / `.env.example` — 7-stage structure, auto-write labels, `ENTRA_APP_NAME` + `CONNECTOR_NAME` configurable
- [x] `_common/Config.ps1` — `Set-EnvValue` helper, `$script:RequiredVars` pattern
- [x] `_common/Connect-Graph.ps1` — service principal auth (non-interactive)
- [x] `entra/00` — full pre-flight validation (8 checks, PASS/WARN/FAIL output)
- [x] `entra/01` — app registration, idempotent, writes CLIENT_ID
- [x] `entra/02` — 11 permissions, admin consent for roles + delegated, idempotent
- [x] `entra/03` — client secret, writes CLIENT_SECRET, warns to store in password manager
- [x] `nexus/01–06` — stubs with `Set-EnvValue` wired for auto-write on all outputs
- [x] `m365/01` — beta API + portal fallback for connector visibility
- [x] `m365/02` — Copilot license report
- [x] `m365/03` — connector health check
- [x] `copilot/01` — PAC CLI connector creation, dynamic apiProperties.json, per-connector redirect URI auto-detected + added to Entra app, smoke test fixed — **tested live 2026-05-11**
- [x] `copilot/02` — guided agent walkthrough (Steps A–E)
- [x] `copilot/03` — guided publish + admin approval walkthrough
- [x] `setup/01–03` — macOS Apple Silicon toolchain, verified working
- [x] All hardcoded names parameterized via `.env`
- [x] Auth caching documented across entra scripts
- [x] `README.md`, `docs/01-prerequisites.md`, `docs/05-powershell-setup.md` — current
