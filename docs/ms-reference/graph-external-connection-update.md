# Microsoft Graph: externalConnection Update & Copilot Visibility

**Source:** https://learn.microsoft.com/en-us/graph/api/resources/externalconnectors-externalconnection?view=graph-rest-beta  
**Retrieved:** 2026-05-05

---

## Key Finding: `enabledContentExperiences` (beta only)

The `externalConnection` resource has an `enabledContentExperiences` property in the **beta** API that controls which content experiences the connector participates in. The documentation describes only `search` as a possible value, but this is the property that corresponds to the admin center toggles.

**As of the documentation retrieved on 2026-05-05:**
- The property is present on the beta resource definition (`graph-rest-beta`)
- It is **NOT present** on the v1.0 resource definition
- The beta update endpoint (`PATCH /beta/external/connections/{id}`) only explicitly lists `name`, `description`, and `configuration` as updatable — `enabledContentExperiences` is not listed as an officially documented updatable property via PATCH
- No `copilot` enum value is documented; only `search` is listed

---

## `externalConnection` Resource Properties (beta)

From `https://learn.microsoft.com/en-us/graph/api/resources/externalconnectors-externalconnection?view=graph-rest-beta`:

| Property | Type | Description |
|---|---|---|
| activitySettings | activitySettings | Settings for activities involving connector content |
| configuration | configuration | Additional app IDs allowed to manage the connection |
| connectorId | String | The Teams App ID |
| contentCategory | contentCategory | Domain category: `uncategorized`, `knowledgeBase`, `wikis`, `fileRepository`, `qna`, `crm`, `dashboard`, `people`, `media`, `email`, `messaging`, `meetingTranscripts`, `taskManagement`, `learningManagement` |
| description | String | Description shown in M365 admin center |
| **enabledContentExperiences** | **contentExperienceType collection** | **"The list of content experiences the connection will participate in. Possible values are `search`."** |
| id | String | Unique connection ID |
| ingestedItemsCount | Int64 | Number of ingested items (beta only) |
| name | String | Display name in M365 admin center |
| searchSettings | searchSettings | Search result display templates |
| state | connectionState | `draft`, `ready`, `obsolete`, `limitExceeded` |

### JSON Representation (beta)
```json
{
  "activitySettings": {"@odata.type": "microsoft.graph.externalConnectors.activitySettings"},
  "configuration": {"@odata.type": "microsoft.graph.externalConnectors.configuration"},
  "connectorId": "String",
  "description": "String",
  "enabledContentExperiences": "[String]",
  "id": "String (identifier)",
  "ingestedItemsCount": "Int64",
  "name": "String",
  "searchSettings": {"@odata.type": "microsoft.graph.externalConnectors.searchSettings"},
  "state": "String"
}
```

---

## v1.0 vs Beta Comparison

| Feature | v1.0 | beta |
|---|---|---|
| `enabledContentExperiences` property | NOT present | Present (documented, `search` only) |
| `ingestedItemsCount` property | NOT present | Present |
| Officially updatable via PATCH | `name`, `description`, `configuration` | `name`, `description`, `configuration` (enabledContentExperiences NOT in update doc) |

---

## The "Give Visibility to Copilot" Toggle — Current Situation

The **"Give visibility to Copilot"** toggle in M365 Admin Center > Search & intelligence corresponds to the `enabledContentExperiences` property. However:

1. **The `contentExperienceType` enum only lists `search`** in the official docs — there is no `copilot` or `microsoftCopilot` value documented.
2. **The PATCH update API does not list `enabledContentExperiences` as updatable** in either v1.0 or beta documentation.
3. **No official API example** exists in the MS docs showing how to programmatically toggle Copilot visibility.

### What the docs say about updating content experiences

From `https://learn.microsoft.com/en-us/graph/connecting-external-content-manage-connections`:

> "To change the display name, description, or **enabled content experiences** for an existing connection, you can update the connection."

This confirms the *intent* exists to update `enabledContentExperiences` via PATCH, but the formal API reference does not document it as an updatable field or show a `copilot` value.

---

## Speculative PATCH call (not officially documented)

Based on the resource definition and the conceptual doc's mention of updating "enabled content experiences," the call would likely be:

```http
PATCH https://graph.microsoft.com/beta/external/connections/{connectionId}
Content-Type: application/json
Authorization: Bearer {token}

{
  "enabledContentExperiences": ["search", "copilotSearch"]
}
```

**Note:** The exact value for enabling Copilot is not confirmed in official documentation. `copilotSearch` is a speculative value — the docs only confirm `search`.

---

## Permissions Required

| Permission type | Minimum permission |
|---|---|
| Delegated (work or school) | ExternalConnection.ReadWrite.OwnedBy |
| Application | ExternalConnection.ReadWrite.OwnedBy |

---

## Related Resources

- [externalConnection resource (v1.0)](https://learn.microsoft.com/en-us/graph/api/resources/externalconnectors-externalconnection?view=graph-rest-1.0)
- [externalConnection resource (beta)](https://learn.microsoft.com/en-us/graph/api/resources/externalconnectors-externalconnection?view=graph-rest-beta)
- [Update externalConnection (v1.0)](https://learn.microsoft.com/en-us/graph/api/externalconnectors-externalconnection-update?view=graph-rest-1.0)
- [Update externalConnection (beta)](https://learn.microsoft.com/en-us/graph/api/externalconnectors-externalconnection-update?view=graph-rest-beta)
- [Manage connections conceptual guide](https://learn.microsoft.com/en-us/graph/connecting-external-content-manage-connections)
