# Create, Update, and Delete Items in a Microsoft Graph Connection
Source: https://learn.microsoft.com/en-us/graph/api/externalconnectors-externalconnection-post-items
Fetched: 2026-05-05

> **Note:** The originally requested URL returned HTTP 404. This file contains the closest available content from the Microsoft Graph documentation covering external item creation via Copilot connectors. The direct API reference page may have been moved or renamed. Canonical equivalent: https://learn.microsoft.com/en-us/graph/connecting-external-content-manage-items

---

# Create, update, and delete items in a Microsoft Graph connection - Microsoft Graph | Microsoft Learn

Microsoft 365 Copilot connectors (formerly Microsoft Graph connectors) offer an intuitive way to bring external data into Microsoft Graph. Items your application adds to the Microsoft Search service are represented by the [externalItem](/en-us/graph/api/resources/externalconnectors-externalitem) resource in Microsoft Graph.

After you [create a connection](/en-us/graph/api/externalconnectors-external-post-connections), you can add your content. Each item from your data source must be represented as an **externalItem** in Microsoft Graph with a unique item ID. This ID is used to create, update, or delete the item from Microsoft Graph. You can use the primary key from your data source as the item ID or derive it from one or more fields.

## Key components

An **externalItem** has three key components: access control list, properties, and content.

### Access control list

The access control list (ACL) is used to specify whether the given roles are granted or denied access to view items in Microsoft experiences. The ACL is an array of access control entries representing a Microsoft Entra user or group. A third access control entry type `Everyone` represents all the users in the tenant.

The **accessType** value `deny` takes precedence over `grant`. For example, in the item shown earlier, while `Everyone` is granted access and a specific user is denied access, the effective permission for this user is `deny`.

If your data source has non-Azure AD groups (such as teams within your helpdesk system) that are used to set permissions for the item, you can create external groups in Microsoft Graph by using the group sync APIs to replicate the `allow` or `deny` permissions. Avoid expanding the membership of your external groups directly into the ACLs of individual items because each group membership can lead to a high volume of item updates.

External groups include another group, Microsoft Entra users, and Microsoft Entra groups. If you have non-Azure AD users, you must translate them to Microsoft Entra users in your ACL.

### Properties

The properties component is used to add item metadata that is useful in Microsoft Graph experiences. You must [register the schema](connecting-external-content-manage-schema) for the connection before adding items into it and convert **datatypes** into supported datatypes.

### Content

The content component adds the bulk of the item that needs to be full-text indexed. Examples include a ticket description, parsed text from a file body, or a wiki page body.

Content is one of the key fields influencing relevance across Microsoft experiences. The content types `text` and `html` are supported. If your data source has other content types, such as binary files, videos, or images, you can parse them to text before adding them to Microsoft Graph.

> **Important:** The compliance solution only supports `text` for the content type. If you enable the connection for compliance by setting the **enabledContentExperience** property to `compliance`, you should ingest content in plain text format and set the content type to `text`.

Content can't be directly added into a search result template, but you can use a generated result snippet, which is a dynamically generated preview of the relevant sections within content.

When content in your data source changes, you must sync it with your connection items. You can either update the entire item or one or more components. After adding your content to Microsoft Graph, you can search for it through the Microsoft Search experience after setting up search verticals and result types or by using the Microsoft Graph Search API.

### Activities

The activities component is a transient property that sends activities on the item. You can **only** write to this property.

An activity consists of an actor (who performed the activity), a time (when the activity was performed), and an activity type (what type of activity was performed).

Sending activities on the item powers intelligent recommendation experiences across Microsoft 365. End users can receive content tailored to them based on the activities that are sent.

## Add an item

To add an item to the index, you create an externalItem. When you create an item, you assign a unique identifier in the URL.

For example, your application might index helpdesk tickets using the ticket number. If a ticket has the ticket number `SR00145`, the request might look like the following:

```http
PUT /external/connections/contosohelpdesk/items/SR00145
Content-Type: application/json

"properties": {
  "title": "WiFi outage in Conference Room A",
  "priority": 1,
  "assignee": "meganb@contoso.com"
}
```

> **Note:** Before indexed items can be found in the Microsoft Search UI, an administrator must customize the search results page for the corresponding connection.

## Add activities to an item

To add activities to an item, you call the `addActivities` endpoint, with the same unique identifier for that item in the URL.

For example, if someone with Microsoft Entra ID `18948b93-d3ed-4307-9981-10fc36a08a52` commented on the helpdesk ticket with ticket number `SR00145` on April 11, 2022, at 4:25 PM:

```http
POST /external/connections/contosohelpdesk/items/SR00145/addActivities
Content-Type: application/json

"activities": [
 {
   "type": "commented",
   "startDateTime": "2022-04-11T16:25:34.3202005Z",
   "performedBy": {
       "id": "18948b93-d3ed-4307-9981-10fc36a08a52",
       "type": "user"
    }
  }
]
```

You can also add an activity to an item in the same request that creates the item. Add the activity as another entity, like `acl` and `content`. If you add an activity this way, include the `@odata.type` for the activity, or the request fails. Activities with timestamps older than seven days don't surface in the Microsoft 365 app.

## Update an item

When an item is updated in the external service, you can update its entry in the index by updating the externalItem, using the unique identifier assigned to the item when you created it.

```http
PATCH /external/connections/contosohelpdesk/items/SR00145
Content-Type: application/json

{
  "assignee": "alexw@contoso.com"
}
```

## Delete an item

To remove items from the index, you delete the externalItem, using the unique identifier assigned to the item when you created it.

```http
DELETE /external/connections/contosohelpdesk/items/SR00145
```

## Keep your data in sync

Consider the following information when you choose how to keep your data in sync:

**Crawl mechanism:**

- **Incremental crawl**: Detects and pushes additions in source data; less performance-intensive than a full crawl.
- **Full crawl**: Updates the entire item from the source data (re-crawl), capturing all additions and deletions; ensures better accuracy but is more time-consuming and performance-intensive than an incremental crawl.

**Sync interval:**

- **Event-based**: Pushes item updates on an event basis. Recommended for dynamic or sensitive data such as item status.
- **Scheduled**: Pushes item updates at regular intervals (every N minutes). Recommended for content-rich or non-sensitive data that is less frequently updated such as wikis or webpages.

Ultimately, the choice of data refresh strategy depends on your data type and computing capabilities.
