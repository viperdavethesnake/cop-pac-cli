# searchEntity: query - Microsoft Graph v1.0
Source: https://learn.microsoft.com/en-us/graph/api/search-query
Fetched: 2026-05-05

---

# searchEntity: query

Namespace: microsoft.graph

Runs the query specified in the request body. Search results are provided in the response.

This API is available in the following national cloud deployments:

| Global service | US Government L4 | US Government L5 (DOD) | China operated by 21Vianet |
| --- | --- | --- | --- |
| Yes | Yes | Yes | Yes |

## Permissions

Choose the permission or permissions marked as least privileged for this API. Use a higher privileged permission or permissions only if your app requires it. For details about delegated and application permissions, see [Permission types](https://learn.microsoft.com/en-us/graph/permissions-overview#permission-types).

| Permission type | Least privileged permissions | Higher privileged permissions |
| --- | --- | --- |
| Delegated (work or school account) | Mail.Read | Acronym.Read.All, Bookmark.Read.All, Calendars.Read, Chat.Read, ExternalItem.Read.All, Files.Read.All, QnA.Read.All, Sites.Read.All |
| Delegated (personal Microsoft account) | Not supported. | Not supported. |
| Application | Files.Read.All | Sites.Read.All |

## HTTP request

```http
POST /search/query
```

## Request headers

| Name | Description |
| --- | --- |
| Authorization | Bearer {token}. Required. |
| Content-type | application/json. Required. |

## Request body

In the request body, provide a JSON object with the following parameters.

| Parameter | Type | Description |
| --- | --- | --- |
| requests | searchRequest collection | A collection of one or more search requests each formatted in a JSON blob. Each JSON blob contains the types of resources expected in the response, the underlying sources, paging parameters, requested fields, and actual search query. Be aware of known limitations on searching specific combinations of entity types, and sorting or aggregating search results. |

## Response

If successful, this method returns `HTTP 200 OK` response code and a searchResponse collection object in the response body.

## Examples

### Example 1: Basic call to perform a search request

The following example shows how to search for expected connector items.

#### Request

```http
POST https://graph.microsoft.com/v1.0/search/query
Content-type: application/json

{
  "requests": [
    {
      "entityTypes": [
        "externalItem"
      ],
      "contentSources": [
        "/external/connections/connectionfriendlyname"
      ],
       "region": "US",
       "query": {
        "queryString": "contoso product"
      },
      "from": 0,
      "size": 25,
      "fields": [
        "title",
        "description"
      ]
    }
  ]
}
```

#### Response

```http
HTTP/1.1 200 OK
Content-type: application/json

{
  "value": [
    {
      "searchTerms": [
        "searchTerms-value"
      ],
      "hitsContainers": [
        {
          "hits": [
            {
              "hitId": "1",
              "rank": 1,
              "summary": "_summary-value",
              "resource": "The source field will contain the underlying graph entity part of the response"
            }
          ],
          "total": 47,
          "moreResultsAvailable": true
        }
      ]
    }
  ]
}
```

#### PowerShell snippet

```powershell
Import-Module Microsoft.Graph.Search

$params = @{
    requests = @(
        @{
            entityTypes = @("externalItem")
            contentSources = @("/external/connections/connectionfriendlyname")
            region = "US"
            query = @{
                queryString = "contoso product"
            }
            from = 0
            size = 25
            fields = @("title", "description")
        }
    )
}

Invoke-MgQuerySearch -BodyParameter $params
```

### Example 2: Basic call to use queryTemplate

The following example shows how to use the queryable property **createdBy** to retrieve all files created by a user.

#### Request

```http
POST https://graph.microsoft.com/v1.0/search/query
Content-type: application/json

{
  "requests": [
    {
      "entityTypes": [
        "listItem"
      ],
        "region": "US",
        "query": {
        "queryString": "contoso",
        "queryTemplate":"{searchTerms} CreatedBy:Bob"
      },
      "from": 0,
      "size": 25
    }
  ]
}
```

#### Response

```http
HTTP/1.1 200 OK
Content-type: application/json

{
    "value": [
        {
            "searchTerms": [
                "contoso"
            ],
            "hitsContainers": [
                {
                    "hits": [
                        {
                            "hitId": "1",
                            "rank": 1,
                            "summary": "_summary-value",
                            "resource": {
                                "@odata.type": "#microsoft.graph.listItem",
                                "id": "c23c7035-73d6-4bad-8901-9e2930d4be8e",
                                "createdBy": {
                                    "user": {
                                        "displayName": "Bob",
                                        "email": "Bob@contoso.com"
                                    }
                                },
                                "createdDateTime": "2021-11-19T17:04:18Z",
                                "lastModifiedDateTime": "2023-03-09T18:52:26Z"
                            }
                        }
                    ],
                    "total": 1,
                    "moreResultsAvailable": false
                }
            ]
        }
    ]
}
```

#### PowerShell snippet

```powershell
Import-Module Microsoft.Graph.Search

$params = @{
    requests = @(
        @{
            entityTypes = @("listItem")
            region = "US"
            query = @{
                queryString = "contoso"
                queryTemplate = '{searchTerms} CreatedBy:Bob'
            }
            from = 0
            size = 25
        }
    )
}

Invoke-MgQuerySearch -BodyParameter $params
```

## See also

- [graph-rest-beta version](https://learn.microsoft.com/en-us/graph/api/search-query?view=graph-rest-beta)
