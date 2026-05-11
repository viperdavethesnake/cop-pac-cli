# New-MgOauth2PermissionGrant (Microsoft.Graph.Identity.SignIns)
Source: https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.signins/new-mgoauth2permissiongrant
Fetched: 2026-05-05

---

# New-MgOauth2PermissionGrant

- Module:
    - [Microsoft.Graph.Identity.SignIns Module](./)

Create a delegated permission grant represented by an oAuth2PermissionGrant object. A delegated permission grant authorizes a client service principal (representing a client application) to access a resource service principal (representing an API), on behalf of a signed-in user, for the level of access limited by the delegated permissions which were granted.

> **Note:** To view the beta release of this cmdlet, view [New-MgBetaOauth2PermissionGrant](https://learn.microsoft.com/en-us/powershell/module/Microsoft.Graph.Beta.Identity.SignIns/New-MgBetaOauth2PermissionGrant?view=graph-powershell-beta)

## Syntax

### CreateExpanded (Default)

```powershell
New-MgOauth2PermissionGrant
    [-ResponseHeadersVariable <string>]
    [-AdditionalProperties <hashtable>]
    [-ClientId <string>]
    [-ConsentType <string>]
    [-Id <string>]
    [-PrincipalId <string>]
    [-ResourceId <string>]
    [-Scope <string>]
    [-Break]
    [-Headers <IDictionary>]
    [-HttpPipelineAppend <SendAsyncStep[]>]
    [-HttpPipelinePrepend <SendAsyncStep[]>]
    [-Proxy <uri>]
    [-ProxyCredential <pscredential>]
    [-ProxyUseDefaultCredentials]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### Create

```powershell
New-MgOauth2PermissionGrant
    -BodyParameter <IMicrosoftGraphOAuth2PermissionGrant>
    [-ResponseHeadersVariable <string>]
    [-Break]
    [-Headers <IDictionary>]
    [-HttpPipelineAppend <SendAsyncStep[]>]
    [-HttpPipelinePrepend <SendAsyncStep[]>]
    [-Proxy <uri>]
    [-ProxyCredential <pscredential>]
    [-ProxyUseDefaultCredentials]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

Create a delegated permission grant represented by an oAuth2PermissionGrant object. A delegated permission grant authorizes a client service principal (representing a client application) to access a resource service principal (representing an API), on behalf of a signed-in user, for the level of access limited by the delegated permissions which were granted.

**Permissions**

| Permission type | Permissions (from least to most privileged) |
| --- | --- |
| Delegated (work or school account) | DelegatedPermissionGrant.ReadWrite.All, Directory.ReadWrite.All |
| Delegated (personal Microsoft account) | Not supported |
| Application | DelegatedPermissionGrant.ReadWrite.All, Directory.ReadWrite.All |

## Examples

### Example 1: Code snippet

```powershell
Import-Module Microsoft.Graph.Identity.SignIns

$params = @{
    clientId = "ef969797-201d-4f6b-960c-e9ed5f31dab5"
    consentType = "AllPrincipals"
    resourceId = "943603e4-e787-4fe9-93d1-e30f749aae39"
    scope = "DelegatedPermissionGrant.ReadWrite.All"
}

New-MgOauth2PermissionGrant -BodyParameter $params
```

This example shows how to use the New-MgOauth2PermissionGrant Cmdlet.

## Parameters

### -AdditionalProperties

Additional Parameters

| Property | Value |
| --- | --- |
| Type | System.Collections.Hashtable |
| Mandatory | False |

### -BodyParameter

oAuth2PermissionGrant. To construct, see NOTES section for BODYPARAMETER properties and create a hash table.

| Property | Value |
| --- | --- |
| Type | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphOAuth2PermissionGrant |
| Mandatory | True (Create parameter set) |

### -Break

Wait for .NET debugger to attach

| Property | Value |
| --- | --- |
| Type | System.Management.Automation.SwitchParameter |
| Default value | False |
| Mandatory | False |

### -ClientId

The object id (not appId) of the client service principal for the application that's authorized to act on behalf of a signed-in user when accessing an API. Required. Supports $filter (eq only).

| Property | Value |
| --- | --- |
| Type | System.String |
| Mandatory | False |

### -Confirm

Prompts you for confirmation before running the cmdlet. Alias: `cf`

### -ConsentType

Indicates if authorization is granted for the client application to impersonate all users or only a specific user. `AllPrincipals` indicates authorization to impersonate all users. `Principal` indicates authorization to impersonate a specific user. Consent on behalf of all users can be granted by an administrator. Nonadmin users might be authorized to consent on behalf of themselves in some cases, for some delegated permissions. Required. Supports $filter (eq only).

| Property | Value |
| --- | --- |
| Type | System.String |
| Mandatory | False |

### -Headers

Optional headers that will be added to the request.

| Property | Value |
| --- | --- |
| Type | System.Collections.IDictionary |
| Mandatory | False |

### -HttpPipelineAppend

SendAsync Pipeline Steps to be appended to the front of the pipeline

### -HttpPipelinePrepend

SendAsync Pipeline Steps to be prepended to the front of the pipeline

### -Id

The unique identifier for an entity. Read-only.

| Property | Value |
| --- | --- |
| Type | System.String |
| Mandatory | False |

### -PrincipalId

The id of the user on behalf of whom the client is authorized to access the resource, when consentType is `Principal`. If consentType is `AllPrincipals` this value is null. Required when consentType is `Principal`. Supports $filter (eq only).

| Property | Value |
| --- | --- |
| Type | System.String |
| Mandatory | False |

### -Proxy

The URI for the proxy server to use

### -ProxyCredential

Credentials for a proxy server to use for the remote call

### -ProxyUseDefaultCredentials

Use the default credentials for the proxy

### -ResourceId

The id of the resource service principal to which access is authorized. This identifies the API that the client is authorized to attempt to call on behalf of a signed-in user. Supports $filter (eq only).

| Property | Value |
| --- | --- |
| Type | System.String |
| Mandatory | False |

### -ResponseHeadersVariable

Optional Response Headers Variable. Alias: `RHV`

### -Scope

A space-separated list of the claim values for delegated permissions that should be included in access tokens for the resource application (the API). For example, `openid User.Read GroupMember.Read.All`. Each claim value should match the value field of one of the delegated permissions defined by the API, listed in the oauth2PermissionScopes property of the resource service principal. Must not exceed 3,850 characters in length.

| Property | Value |
| --- | --- |
| Type | System.String |
| Mandatory | False |

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions. Alias: `wi`

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## Inputs

- `Microsoft.Graph.PowerShell.Models.IMicrosoftGraphOAuth2PermissionGrant`
- `System.Collections.IDictionary`

## Outputs

- `Microsoft.Graph.PowerShell.Models.IMicrosoftGraphOAuth2PermissionGrant`

## Notes

**COMPLEX PARAMETER PROPERTIES**

**BODYPARAMETER** `<IMicrosoftGraphOAuth2PermissionGrant>`:
- `[(Any) <Object>]`: This indicates any property can be added to this object.
- `[Id <String>]`: The unique identifier for an entity. Read-only.
- `[ClientId <String>]`: The object id (not appId) of the client service principal. Required. Supports $filter (eq only).
- `[ConsentType <String>]`: AllPrincipals or Principal. Required. Supports $filter (eq only).
- `[PrincipalId <String>]`: The id of the user on behalf of whom the client is authorized. Required when consentType is Principal. Supports $filter (eq only).
- `[ResourceId <String>]`: The id of the resource service principal to which access is authorized. Supports $filter (eq only).
- `[Scope <String>]`: A space-separated list of delegated permission claim values. Must not exceed 3,850 characters in length.

## Related Links

- [New-MgOauth2PermissionGrant](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.signins/new-mgoauth2permissiongrant)
- [Graph API Reference](https://learn.microsoft.com/en-us/graph/api/oauth2permissiongrant-post?view=graph-rest-1.0)
