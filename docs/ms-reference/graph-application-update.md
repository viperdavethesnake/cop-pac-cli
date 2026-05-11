# Update application - Microsoft Graph v1.0
Source: https://learn.microsoft.com/en-us/graph/api/application-update
Fetched: 2026-05-05

---

# Update application

Namespace: microsoft.graph

Update the properties of an application object. This API can also update an agentIdentityBlueprint object when the **@odata.type** property is set to `#microsoft.graph.agentIdentityBlueprint`.

> **Important:** Using PATCH to set **passwordCredential** is not supported. Use the [addPassword](https://learn.microsoft.com/en-us/graph/api/application-addpassword) and [removePassword](https://learn.microsoft.com/en-us/graph/api/application-removepassword) methods to update the password or secret for an application.

This API is available in the following national cloud deployments:

| Global service | US Government L4 | US Government L5 (DOD) | China operated by 21Vianet |
| --- | --- | --- | --- |
| Yes | Yes | Yes | Yes |

## Permissions

| Permission type | Least privileged permissions | Higher privileged permissions |
| --- | --- | --- |
| Delegated (work or school account) | Application.ReadWrite.All | Not available. |
| Delegated (personal Microsoft account) | Application.ReadWrite.All | Not available. |
| Application | Application.ReadWrite.OwnedBy | Application.ReadWrite.All |

> **Important:** For delegated access using work or school accounts, the admin must be assigned a supported Microsoft Entra role or a custom role that grants the permissions required. Supported built-in roles include:
> - A non-admin member or guest with default user permissions (unless restricted)
> - Application Developer
> - Directory Writers
> - Hybrid Identity Administrator
> - Security Administrator
> - Cloud Application Administrator
> - Application Administrator

## HTTP request

You can address the application using either its **id** or **appId**. Replace `{applicationObjectId}` with the **id** for the application object.

```http
PATCH /applications/{applicationObjectId}
PATCH /applications(appId='{appId}')
```

To update the logo, use the PUT method:

```http
PUT /applications/{applicationObjectId}/logo
PUT /applications(appId='{appId}')/logo
```

## Request headers

| Name | Description |
| --- | --- |
| Authorization | Bearer {token}. Required. |
| Content-Type | application/json. Required. |

## Request body

In the request body, supply the values for relevant fields that should be updated. Existing properties that aren't included in the request body maintain their previous values or are recalculated based on changes to other property values. For best performance, don't include existing values that haven't changed.

| Property | Type | Description |
| --- | --- | --- |
| api | apiApplication | Specifies settings for an application that implements a web API. |
| appRoles | appRole collection | The collection of roles defined for the application. These roles can be assigned to users, groups, or service principals. Not nullable. |
| displayName | String | The display name for the application. |
| groupMembershipClaims | String | Configures the **groups** claim issued in a user or OAuth 2.0 access token. Valid values: `None`, `SecurityGroup`, `All`. |
| identifierUris | String collection | The URIs that identify the application within its Microsoft Entra tenant, or within a verified custom domain if the application is multitenant. Not nullable. |
| info | informationalUrl | Basic profile information of the application such as app's marketing, support, terms of service, and privacy statement URLs. |
| isFallbackPublicClient | Boolean | Specifies the fallback application type as public client. Default is `false` (confidential client). |
| keyCredentials | keyCredential collection | The collection of key credentials associated with the application. Not nullable. |
| logo | Stream | The main logo for the application. Not nullable. Use the PUT method to update the logo. |
| managerApplications | Guid collection | A collection of application IDs for Microsoft first-party applications designated as managers. Supported only on agentIdentityBlueprint objects. |
| nativeAuthenticationApisEnabled | nativeAuthenticationApisEnabled | Specifies whether the native authentication APIs are enabled. Values: `none`, `all`, `unknownFutureValue`. |
| optionalClaims | optionalClaims | Application developers can configure optional claims in their Microsoft Entra apps to specify which claims they want in tokens. |
| parentalControlSettings | parentalControlSettings | Specifies parental control settings for an application. |
| publicClient | publicClientApplication | Specifies settings for installed clients such as desktop or mobile devices. |
| requiredResourceAccess | requiredResourceAccess collection | Specifies the resources that the application needs to access. No more than 50 resource services (APIs) can be configured. Total required permissions must not exceed 400. Not nullable. |
| samlMetadataUrl | String | The URL where the service exposes SAML metadata for federation. Valid only for single-tenant applications. |
| signInAudience | String | Specifies what Microsoft accounts are supported. Values: `AzureADMyOrg`, `AzureADMultipleOrgs`, `AzureADandPersonalMicrosoftAccount`. |
| spa | spaApplication | Specifies settings for a single-page application, including sign out URLs and redirect URIs. |
| tags | String collection | Custom strings that can be used to categorize and identify the application. Not nullable. |
| tokenEncryptionKeyId | String | Specifies the keyId of a public key from the keyCredentials collection. When configured, Microsoft Entra ID encrypts all tokens using this key. |
| uniqueName | String | The unique identifier that can be assigned to an application and used as an alternate key. Can be updated only if `null` and is immutable once set. |
| web | webApplication | Specifies settings for a web application. |

## Response

If successful, this method returns a `204 No Content` response code and does not return anything in the response body.

## Examples

### Example 1: Update the displayName for an application

#### Request

```http
PATCH https://graph.microsoft.com/v1.0/applications/{id}
Content-type: application/json

{
  "displayName": "New display name"
}
```

#### PowerShell snippet

```powershell
Import-Module Microsoft.Graph.Applications

$params = @{
    displayName = "New display name"
}

Update-MgApplication -ApplicationId $applicationId -BodyParameter $params
```

#### Response

```http
HTTP/1.1 204 No Content
```

### Example 2: Update the appRoles for an application

The following example updates the **appRoles** collection for an application. To keep any existing app roles, include them in the request. Any existing objects in the collection that aren't included in the request are replaced with the new objects.

#### Request

```http
PATCH https://graph.microsoft.com/v1.0/applications/fda284b5-f0ad-4763-8289-31a273fca865
Content-type: application/json

{
    "appRoles": [
        {
            "allowedMemberTypes": [
                "User",
                "Application"
            ],
            "description": "Survey.Read",
            "displayName": "Survey.Read",
            "id": "ebb7c86c-fb47-4e3f-8191-420ff1b9de4a",
            "isEnabled": false,
            "origin": "Application",
            "value": "Survey.Read"
        }
    ]
}
```

#### PowerShell snippet

```powershell
Import-Module Microsoft.Graph.Applications

$params = @{
    appRoles = @(
        @{
            allowedMemberTypes = @("User", "Application")
            description = "Survey.Read"
            displayName = "Survey.Read"
            id = "ebb7c86c-fb47-4e3f-8191-420ff1b9de4a"
            isEnabled = $false
            origin = "Application"
            value = "Survey.Read"
        }
    )
}

Update-MgApplication -ApplicationId $applicationId -BodyParameter $params
```

#### Response

```http
HTTP/1.1 204 No Content
```

## See also

- [graph-rest-beta version](https://learn.microsoft.com/en-us/graph/api/application-update?view=graph-rest-beta)
- [application-addpassword](https://learn.microsoft.com/en-us/graph/api/application-addpassword)
- [application-removepassword](https://learn.microsoft.com/en-us/graph/api/application-removepassword)
