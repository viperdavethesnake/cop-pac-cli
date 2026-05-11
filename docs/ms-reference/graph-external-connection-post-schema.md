# Register and Update Schema for the Microsoft Graph Connection
Source: https://learn.microsoft.com/en-us/graph/api/externalconnectors-externalconnection-post-schema
Fetched: 2026-05-05

> **Note:** The originally requested URL returned HTTP 404. This file contains the closest available content from the Microsoft Graph documentation covering schema registration for external connections. Canonical equivalent: https://learn.microsoft.com/en-us/graph/connecting-external-content-manage-schema

---

# Register and update schema for the Microsoft Graph connection - Microsoft Graph | Microsoft Learn

This guide provides guidance on defining schemas and following best practices for Microsoft 365 Copilot connectors.

The connection [schema](/en-us/graph/api/resources/externalconnectors-schema) defines how your content is used across Microsoft 365 Copilot experiences. A schema is a flat list of all the properties you plan to add to the connection. Each property includes attributes, labels, and aliases. You must register the schema before adding items to the connection.

The following table shows an example schema for a work ticket system connector:

| Property | Type | Searchable | Queryable | Retrievable | Refinable | Exact match required | Labels | Aliases |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ticketId | String |  | ✔️ |  |  | ✔️ |  | ID |
| title | String | ✔️ | ✔️ | ✔️ |  |  | title |  |
| createdBy | String | ✔️ | ✔️ |  |  |  | createdBy | creator |
| assignedTo | String | ✔️ | ✔️ |  |  |  |  |  |
| lastEditedDate | DateTime |  | ✔️ | ✔️ | ✔️ |  | lastModifiedDateTime | editedDate |
| lastEditedBy | String | ✔️ | ✔️ | ✔️ |  |  | lastModifiedBy | edited |
| workItemType | String |  | ✔️ | ✔️ |  |  |  | ticketType |
| priority | Int64 | ✔️ |  |  |  |  |  |  |
| tags | StringCollection |  | ✔️ | ✔️ | ✔️ | ✔️ |  |  |
| status | String |  | ✔️ | ✔️ |  |  |  |  |
| url | String |  |  |  |  |  | url |  |
| resolved | Boolean |  | ✔️ | ✔️ |  |  |  |  |

For schema object and API reference, see the [schema](/en-us/graph/api/resources/externalconnectors-schema) section in the [Copilot Connector API reference](/en-us/graph/api/resources/connectors-api-overview).

## Schema attributes

This section describes each schema attribute and provides best practices for using them.

### Property

This attribute refers to the name of the property.

**Best practices:**

- **Use clear and unique names** – Ensure property names are easy to understand and distinguish. Avoid ambiguous names like `orgName`, `brOrgName`, or `tpOrgName`. Instead, use descriptive names such as `parentOrganizationName` or `departmentName`.
- **Avoid overly technical or cryptic names** – Replace names like `dataBlob` or `ftxInvIsLead` with meaningful alternatives like `incidentRootCause` or `qualifiedSalesLead`.
- **Add property descriptions** – Descriptions help Copilot better understand and match properties to user queries.

> **Note:** Support for adding property descriptions to custom connectors is expected in Q4 2025. When using declarative agents (DA), include property descriptions in the DA instruction set.

### Searchable

When a property is marked as searchable, its value is added to the full-text index. This allows Copilot to return results when a user's query matches the property or its content.

**Mark a property as searchable if:**

- It contains **textual data** users are likely to search for.
- It's **relevant to search queries** (e.g., titles, descriptions, tags).
- You want it to contribute to **search hits** and **snippet generation**.

**Common examples:** `title`, `description`, `tags`, `createdBy`, `assignedTo`.

**Best practices:**

- Avoid marking large binary fields as searchable.
- Don't mark refinable fields as searchable — these attributes are mutually exclusive.
- Only mark properties as searchable if they are essential for search relevance.

### Queryable

Mark a property as **queryable** if users need to filter their search results based on specific values. For example, properties such as `ticketId`, `teamName`, or `created` can be queryable.

**Mark a property as queryable if:**

- It's used for **filtering or narrowing down search results**.
- It represents **categorical or structured data** (for example, status, priority, assigned user).
- You want to support **custom search experiences** or **faceted navigation**.

**Common examples:** `status`, `assignedTo`, `priority`, `category`, `type`.

**Best practices:**

- Avoid marking large text fields (like descriptions) as queryable.
- Combine `Queryable: true` with `Retrievable: true` so the property can be used and shown in results.
- Use `Refinable: true` if you want the property to appear as a **filter in the UI**.

If a property is queryable, you can query against it using **KQL (Keyword Query Language)**. KQL supports free-text keywords and property restrictions. Prefix matching with the wildcard operator (`*`) is supported.

> **Note:** Suffix matching is not supported.

### Retrievable

Mark a property as **retrievable** if its value should be returned in search results. Any property that appears in the display template or is returned from a query must be retrievable. Be selective — marking too many or large properties as retrievable can increase search latency.

**Mark a property as retrievable if:**

- You want it to be **visible in search results**.
- It provides **contextual information** (e.g., title, status, assigned user).

**Common examples:** `title`, `summary`, `description`, `status`, `assignedTo`, `createdDateTime`.

**Best practices:**

- Avoid marking sensitive or irrelevant fields as retrievable.
- Use `Retrievable: true` for fields shown in **search cards**, **Copilot prompts**, or **custom UI**.

### Refinable

Mark a property as **refinable** if you want it to be used as a filter in Microsoft Search experiences. Refinable properties can be configured by admins to appear as custom filters on the search results page.

When a property is refinable:

- It can be used to **narrow down search results**.
- It appears as a **refiner control** (e.g., dropdown or checkbox) in the UI.
- It supports **aggregation** in search queries.

**Mark a property as refinable if:**

- It represents **categorical or structured data**.
- You want users to **filter or group** results by these values.

**Common examples:** `tags`, `status`, `priority`, `category`, `type`.

**Best practices:**

- **Refinable and searchable are mutually exclusive** — a property cannot be both.
- Only **string or numeric types** can be refinable.
- Marking too many properties as refinable can **impact performance**.

### Exact match required

If `isExactMatchRequired` is set to `true` for a property, the full string value is indexed. This setting can **only** be applied to properties that are **not searchable**.

For example, the `ticketId` property is both queryable and requires exact matching:

- Querying `ticketId:CTS-ce913b61` returns the item with ticket ID **CTS-ce913b61**.
- Querying `ticketId:CTS` does **not** return the item with ticket ID **CTS-ce913b61**.

Similarly, the `tags` property also uses exact matching:

- Querying `tags:contoso` returns items with the tag **contoso**.
- Querying `tags:contoso` does **not** return items with the tag **contoso ticket**.

If `isExactMatchRequired` is not specified, it defaults to `false`.

### Semantic labels

A **semantic label** is a well-known tag published by Microsoft that you can assign to a property in your schema. When building a custom Copilot connector using the Microsoft Graph API, applying semantic labels is essential. These labels help Microsoft 365 Copilot and Microsoft Search understand the meaning and role of each property, improving search, summarization, and overall user experience.

| Label | Description | Applies to fields like |
| --- | --- | --- |
| title | The main name or heading of the item that you want shown in search and other experiences. | documentTitle, ticketSubject, reportName |
| url | The target URL of the item in the data source. The direct link to open the item in its original system. | documentLink, ticketUrl, recordUrl |
| createdBy | Identifies the user who originally created the item in the data source. | authorEmail, submittedBy, createdByUser |
| lastModifiedBy | The name of the user who most recently edited the item in the data source. | editorEmail, updatedBy, lastChangedBy |
| authors | The names of all the people who participated/collaborated on the item in the data source. | authorName, writer, reportAuthor |
| createdDateTime | The date and time that the item was created in the data source. | createdOn, submissionDate, entryDate |
| lastModifiedDateTime | The date and time that the item was last modified in the data source. | lastUpdated, modifiedOn, changeDate |
| fileName | The name of the file in the data source. | projectUrl, folderLink, groupPage |
| fileExtension | The extension of the file in the data source. | documentType, attachmentType, format |
| iconUrl | The URL of an icon. | thumbnailUrl, logo, previewImage |
| containerName | The name of the container (e.g., a project or OneDrive folder). | projectName, folderName, groupName |
| containerUrl | The URL of the container. | projectUrl, folderLink, groupPage |

**Best practices:**

- Add as many labels as are relevant, but ensure they are accurately mapped.
- Do **not** assign a label to a property if it doesn't match its purpose — incorrect mappings degrade the experience.

> **Important:** Properties must be marked as **retrievable** before they can be mapped to labels.

The `title` label is the most important. Assigning a property to this label enables your connection to participate in the **result cluster experience**.

### Relevance

Applying accurately mapped semantic labels improves the discoverability of your content through search. Microsoft recommends defining as many of the following labels as possible, listed in descending order of their impact on discovery: **title**, **lastModifiedDateTime**, **lastModifiedBy**, **url**, **fileName**, and **fileExtension**.

### Rank hints

Rank hints can be applied to textual properties that:

- Are **searchable**
- Are **not mapped** to semantic labels

Rank hints help prioritize certain properties in search results. You can set their importance from **default** to **very high** in the Microsoft 365 Search admin portal.

### Default result types

Semantic labels also influence how **default result types** are generated. At a minimum, assigning the `title` and `content` labels ensures that a result type is created for your connection.

To enhance the default result experience, define the following labels when applicable (listed in ascending order of impact): **title**, **url**, **lastModifiedBy**, **lastModifiedDateTime**, **fileName**, and **fileExtension**.

**Validation checklist for assigning labels:**

- Properties assigned to labels must be marked as **retrievable**.
- The **data type** of the property must match the expected type for the label.
- Each label should be mapped to **exactly one property**.

### Aliases

**Aliases** are friendly names assigned to properties. They are used in queries and in refinable property filters to improve usability and query flexibility.

| Property | Possible aliases | Use case |
| --- | --- | --- |
| createdBy | author, owner, submittedBy | Users asking "Who wrote this?" or "Who submitted?" |
| title | subject, heading | Users asking "What's the subject of this item?" |
| tags | labels, categories | Users asking "Show items tagged with Finance" |
| filename | documentName, fileName | Users asking "Find file named report.docx" |
| summary | description, abstract | Users asking "Give me a quick overview" |

**Best practices for aliases:**

- Use aliases for **common synonyms** or **domain-specific terms**.
- Avoid overly generic or ambiguous aliases.
- Keep aliases **short and intuitive**.

### Content property

The **Microsoft Copilot connector schema** supports a **default property** called `content`. Unlike other properties, you do **not** need to define it in the schema. Instead, it is **included directly in the item payload** during data ingestion.

The `content` property is:

- Semantically indexed for **text search**.
- Used to generate **dynamic snippets** in search results.
- Available to Copilot for **summarization** and **semantic understanding**.

**Best practices for using the content property:**

- Add any **unstructured data** to the `content` property to enable Copilot to perform semantic search and match queries effectively.
- For unstructured or free-form content, include properties like `summary`, `comment`, `rootCause`, and `description` in the `content` field.
- You can **append multiple properties** into the `content` field to enrich semantic understanding.

A sample of how the `content` property is used while ingesting data:

```json
{ 
  "@odata.type": "microsoft.graph.externalItem", 
  "acl": [ 
    { 
      "type": "everyone", 
      "value": "everyone", 
      "accessType": "grant" 
    } 
  ], 
  "properties": { 
    "title": "Payment Gateway Error", 
    "priority": "High", 
    "assignee": "john.doe@contoso.com" 
  }, 
  "content": { 
    "value": "Rootcause : Error in payment gateway : MoreDetails about the error.......", 
    "type": "text" 
  } 
}
```

### Declarative agents and property descriptions

If you're using a **declarative agent (DA)**, you should include property descriptions from your **Copilot connector schema** in the **instruction set** provided to the agent. This helps the DA understand:

- The **semantic meaning** of each property
- How to **reference and summarize** the data
- How to **respond to user queries** using the indexed content

## Schema update capabilities

> **Note:** After updating your schema, we recommend reindexing items to align them with the latest schema. Without reingestion, item behavior might be inconsistent.

### Add a property

You can add a new property to your schema. While reingestion is not required, it is recommended. When adding a property, include all necessary search attributes.

### Add or remove a search capability

You can modify search attributes for a property. However:

- You **cannot** add a **refinable** attribute as part of a schema update.
- A property **cannot** be both **searchable** and **refinable**.

Adding or removing a search capability **requires reingestion**.

### Add or remove an alias

You can add or remove aliases for use in search queries. However, aliases that were **autocreated by the system** for refinable properties **cannot be removed**.

### Add or remove a semantic label

You can assign or remove semantic labels. These labels influence experiences such as **Relevance** and **Viva Topics**.
