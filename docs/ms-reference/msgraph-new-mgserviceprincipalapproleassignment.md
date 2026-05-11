# New-MgServicePrincipalAppRoleAssignment (Microsoft.Graph.Applications)
Source: https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.applications/new-mgserviceprincipalapproleassignment
Fetched: 2026-05-05

---

# New-MgServicePrincipalAppRoleAssignment

- Module:
    - [Microsoft.Graph.Applications Module](./)

Assign an app role to a client service principal. App roles that are assigned to service principals are also known as application permissions. Application permissions can be granted directly with app role assignments, or through a consent experience. To grant an app role assignment to a client service principal, you need three identifiers:

> **Note:** To view the beta release of this cmdlet, view [New-MgBetaServicePrincipalAppRoleAssignment](https://learn.microsoft.com/en-us/powershell/module/Microsoft.Graph.Beta.Applications/New-MgBetaServicePrincipalAppRoleAssignment?view=graph-powershell-beta)

## Syntax

### CreateExpanded (Default)

```powershell
New-MgServicePrincipalAppRoleAssignment
    -ServicePrincipalId <string>
    [-ResponseHeadersVariable <string>]
    [-AdditionalProperties <hashtable>]
    [-AppRoleId <string>]
    [-CreatedDateTime <datetime>]
    [-DeletedDateTime <datetime>]
    [-Id <string>]
    [-PrincipalDisplayName <string>]
    [-PrincipalId <string>]
    [-PrincipalType <string>]
    [-ResourceDisplayName <string>]
    [-ResourceId <string>]
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
New-MgServicePrincipalAppRoleAssignment
    -ServicePrincipalId <string>
    -BodyParameter <IMicrosoftGraphAppRoleAssignment>
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

### CreateViaIdentityExpanded

```powershell
New-MgServicePrincipalAppRoleAssignment
    -InputObject <IApplicationsIdentity>
    [-ResponseHeadersVariable <string>]
    [-AdditionalProperties <hashtable>]
    [-AppRoleId <string>]
    [-CreatedDateTime <datetime>]
    [-DeletedDateTime <datetime>]
    [-Id <string>]
    [-PrincipalDisplayName <string>]
    [-PrincipalId <string>]
    [-PrincipalType <string>]
    [-ResourceDisplayName <string>]
    [-ResourceId <string>]
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

### CreateViaIdentity

```powershell
New-MgServicePrincipalAppRoleAssignment
    -InputObject <IApplicationsIdentity>
    -BodyParameter <IMicrosoftGraphAppRoleAssignment>
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

Assign an app role to a client service principal. App roles that are assigned to service principals are also known as application permissions. Application permissions can be granted directly with app role assignments, or through a consent experience. To grant an app role assignment to a client service principal, you need three identifiers:

**Permissions**

| Permission type | Permissions (from least to most privileged) |
| --- | --- |
| Delegated (work or school account) | Directory.Read.All, AppRoleAssignment.ReadWrite.All, Application.Read.All |
| Delegated (personal Microsoft account) | Not supported |
| Application | Directory.Read.All, AppRoleAssignment.ReadWrite.All, Application.Read.All |

## Examples

### Example 1: Code snippet

```powershell
Import-Module Microsoft.Graph.Applications

$params = @{
    principalId = "9028d19c-26a9-4809-8e3f-20ff73e2d75e"
    resourceId = "8fce32da-1246-437b-99cd-76d1d4677bd5"
    appRoleId = "498476ce-e0fe-48b0-b801-37ba7e2685c6"
}

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipalId -BodyParameter $params
```

This example shows how to use the New-MgServicePrincipalAppRoleAssignment Cmdlet.

## Parameters

### -AdditionalProperties

Additional Parameters

| Property | Value |
| --- | --- |
| Type | System.Collections.Hashtable |
| Supports wildcards | False |
| Mandatory | False |

### -AppRoleId

The identifier (id) for the app role that's assigned to the principal. This app role must be exposed in the appRoles property on the resource application's service principal (resourceId). If the resource application hasn't declared any app roles, a default app role ID of 00000000-0000-0000-0000-000000000000 can be specified to signal that the principal is assigned to the resource app without any specific app roles. Required on create.

| Property | Value |
| --- | --- |
| Type | System.String |
| Mandatory | False |

### -BodyParameter

appRoleAssignment. To construct, see NOTES section for BODYPARAMETER properties and create a hash table.

| Property | Value |
| --- | --- |
| Type | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphAppRoleAssignment |
| Mandatory | True (Create, CreateViaIdentity parameter sets) |

### -Break

Wait for .NET debugger to attach

| Property | Value |
| --- | --- |
| Type | System.Management.Automation.SwitchParameter |
| Default value | False |
| Mandatory | False |

### -Confirm

Prompts you for confirmation before running the cmdlet. Alias: `cf`

### -CreatedDateTime

The time when the app role assignment was created. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. Read-only.

| Property | Value |
| --- | --- |
| Type | System.DateTime |
| Mandatory | False |

### -DeletedDateTime

Date and time when this object was deleted. Always null when the object hasn't been deleted.

| Property | Value |
| --- | --- |
| Type | System.DateTime |
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

### -InputObject

Identity Parameter. To construct, see NOTES section for INPUTOBJECT properties and create a hash table.

| Property | Value |
| --- | --- |
| Type | Microsoft.Graph.PowerShell.Models.IApplicationsIdentity |
| Mandatory | True (CreateViaIdentityExpanded, CreateViaIdentity parameter sets) |

### -PrincipalDisplayName

The display name of the user, group, or service principal that was granted the app role assignment. Maximum length is 256 characters. Read-only. Supports $filter (eq and startswith).

### -PrincipalId

The unique identifier (id) for the user, security group, or service principal being granted the app role. Security groups with dynamic memberships are supported. Required on create.

### -PrincipalType

The type of the assigned principal. This can either be User, Group, or ServicePrincipal. Read-only.

### -Proxy

The URI for the proxy server to use

### -ProxyCredential

Credentials for a proxy server to use for the remote call

### -ProxyUseDefaultCredentials

Use the default credentials for the proxy

### -ResourceDisplayName

The display name of the resource app's service principal to which the assignment is made. Maximum length is 256 characters.

### -ResourceId

The unique identifier (id) for the resource service principal for which the assignment is made. Required on create. Supports $filter (eq only).

### -ResponseHeadersVariable

Optional Response Headers Variable. Alias: `RHV`

### -ServicePrincipalId

The unique identifier of servicePrincipal. **Mandatory** for CreateExpanded and Create parameter sets.

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions. Alias: `wi`

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## Inputs

- `Microsoft.Graph.PowerShell.Models.IApplicationsIdentity`
- `Microsoft.Graph.PowerShell.Models.IMicrosoftGraphAppRoleAssignment`
- `System.Collections.IDictionary`

## Outputs

- `Microsoft.Graph.PowerShell.Models.IMicrosoftGraphAppRoleAssignment`

## Notes

**COMPLEX PARAMETER PROPERTIES**

**BODYPARAMETER** `<IMicrosoftGraphAppRoleAssignment>`:
- `[DeletedDateTime <DateTime?>]`: Date and time when this object was deleted. Always null when the object hasn't been deleted.
- `[Id <String>]`: The unique identifier for an entity. Read-only.
- `[AppRoleId <String>]`: The identifier (id) for the app role that's assigned to the principal.
- `[CreatedDateTime <DateTime?>]`: The time when the app role assignment was created. Read-only.
- `[PrincipalDisplayName <String>]`: The display name of the user, group, or service principal. Read-only. Supports $filter (eq and startswith).
- `[PrincipalId <String>]`: The unique identifier (id) for the user, security group, or service principal being granted the app role. Required on create.
- `[PrincipalType <String>]`: The type of the assigned principal: User, Group, or ServicePrincipal. Read-only.
- `[ResourceDisplayName <String>]`: The display name of the resource app's service principal.
- `[ResourceId <String>]`: The unique identifier (id) for the resource service principal. Required on create. Supports $filter (eq only).

**INPUTOBJECT** `<IApplicationsIdentity>`:
- `[AppId <String>]`: Alternate key of application
- `[AppManagementPolicyId <String>]`: The unique identifier of appManagementPolicy
- `[AppRoleAssignmentId <String>]`: The unique identifier of appRoleAssignment
- `[ApplicationId <String>]`: The unique identifier of application
- `[ApplicationTemplateId <String>]`: The unique identifier of applicationTemplate
- `[ClaimsMappingPolicyId <String>]`: The unique identifier of claimsMappingPolicy
- `[DelegatedPermissionClassificationId <String>]`: The unique identifier of delegatedPermissionClassification
- `[DirectoryDefinitionId <String>]`: The unique identifier of directoryDefinition
- `[DirectoryObjectId <String>]`: The unique identifier of directoryObject
- `[EndpointId <String>]`: The unique identifier of endpoint
- `[ExtensionPropertyId <String>]`: The unique identifier of extensionProperty
- `[FederatedIdentityCredentialId <String>]`: The unique identifier of federatedIdentityCredential
- `[GroupId <String>]`: The unique identifier of group
- `[HomeRealmDiscoveryPolicyId <String>]`: The unique identifier of homeRealmDiscoveryPolicy
- `[Name <String>]`: Alternate key of federatedIdentityCredential
- `[OAuth2PermissionGrantId <String>]`: The unique identifier of oAuth2PermissionGrant
- `[ServicePrincipalId <String>]`: The unique identifier of servicePrincipal
- `[SynchronizationJobId <String>]`: The unique identifier of synchronizationJob
- `[SynchronizationTemplateId <String>]`: The unique identifier of synchronizationTemplate
- `[TargetDeviceGroupId <String>]`: The unique identifier of targetDeviceGroup
- `[TokenIssuancePolicyId <String>]`: The unique identifier of tokenIssuancePolicy
- `[TokenLifetimePolicyId <String>]`: The unique identifier of tokenLifetimePolicy
- `[UniqueName <String>]`: Alternate key of application
- `[UserId <String>]`: The unique identifier of user

## Related Links

- [New-MgServicePrincipalAppRoleAssignment](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.applications/new-mgserviceprincipalapproleassignment)
- [Graph API Reference](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-post-approleassignments?view=graph-rest-1.0)
