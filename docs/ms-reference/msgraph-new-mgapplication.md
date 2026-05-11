# New-MgApplication
Source: https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.applications/new-mgapplication
Fetched: 2026-05-05

---

- Module: [Microsoft.Graph.Applications Module](https://learn.microsoft.com/powershell/module/microsoft.graph.applications)

Create a new application object in Microsoft Entra ID.

> **Note:** To view the beta release of this cmdlet, view [New-MgBetaApplication](/en-us/powershell/module/Microsoft.Graph.Beta.Applications/New-MgBetaApplication?view=graph-powershell-beta)

## Syntax

### CreateExpanded (Default)

```powershell
New-MgApplication
    [-ResponseHeadersVariable <string>]
    [-AddIns <IMicrosoftGraphAddIn[]>]
    [-AdditionalProperties <hashtable>]
    [-Api <IMicrosoftGraphApiApplication>]
    [-AppId <string>]
    [-AppManagementPolicies <IMicrosoftGraphAppManagementPolicy[]>]
    [-AppRoles <IMicrosoftGraphAppRole[]>]
    [-ApplicationTemplateId <string>]
    [-AuthenticationBehaviors <IMicrosoftGraphAuthenticationBehaviors>]
    [-Certification <IMicrosoftGraphCertification>]
    [-CreatedDateTime <datetime>]
    [-CreatedOnBehalfOf <IMicrosoftGraphDirectoryObject>]
    [-DefaultRedirectUri <string>]
    [-DeletedDateTime <datetime>]
    [-Description <string>]
    [-DisabledByMicrosoftStatus <string>]
    [-DisplayName <string>]
    [-ExtensionProperties <IMicrosoftGraphExtensionProperty[]>]
    [-FederatedIdentityCredentials <IMicrosoftGraphFederatedIdentityCredential[]>]
    [-GroupMembershipClaims <string>]
    [-HomeRealmDiscoveryPolicies <IMicrosoftGraphHomeRealmDiscoveryPolicy[]>]
    [-Id <string>]
    [-IdentifierUris <string[]>]
    [-Info <IMicrosoftGraphInformationalUrl>]
    [-IsDeviceOnlyAuthSupported]
    [-IsFallbackPublicClient]
    [-KeyCredentials <IMicrosoftGraphKeyCredential[]>]
    [-LogoInputFile <string>]
    [-NativeAuthenticationApisEnabled <string>]
    [-Notes <string>]
    [-Oauth2RequirePostResponse]
    [-OptionalClaims <IMicrosoftGraphOptionalClaims>]
    [-Owners <IMicrosoftGraphDirectoryObject[]>]
    [-ParentalControlSettings <IMicrosoftGraphParentalControlSettings>]
    [-PasswordCredentials <IMicrosoftGraphPasswordCredential[]>]
    [-PublicClient <IMicrosoftGraphPublicClientApplication>]
    [-PublisherDomain <string>]
    [-RequestSignatureVerification <IMicrosoftGraphRequestSignatureVerification>]
    [-RequiredResourceAccess <IMicrosoftGraphRequiredResourceAccess[]>]
    [-SamlMetadataUrl <string>]
    [-ServiceManagementReference <string>]
    [-ServicePrincipalLockConfiguration <IMicrosoftGraphServicePrincipalLockConfiguration>]
    [-SignInAudience <string>]
    [-Spa <IMicrosoftGraphSpaApplication>]
    [-Synchronization <IMicrosoftGraphSynchronization>]
    [-Tags <string[]>]
    [-TokenEncryptionKeyId <string>]
    [-TokenIssuancePolicies <IMicrosoftGraphTokenIssuancePolicy[]>]
    [-TokenLifetimePolicies <IMicrosoftGraphTokenLifetimePolicy[]>]
    [-UniqueName <string>]
    [-VerifiedPublisher <IMicrosoftGraphVerifiedPublisher>]
    [-Web <IMicrosoftGraphWebApplication>]
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
New-MgApplication
    -BodyParameter <IMicrosoftGraphApplication>
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

Create a new application object.

## Permissions

| Permission Type | Permissions (from least to most privileged) |
| --- | --- |
| Delegated (work or school account) | Application.ReadWrite.All |
| Delegated (personal Microsoft account) | Application.ReadWrite.All |
| Application | Application.ReadWrite.OwnedBy, Application.ReadWrite.All |

## Examples

### Example 1: Create a new application

```powershell
New-MgApplication -DisplayName 'New app' |
  Format-List Id, DisplayName, AppId, SignInAudience, PublisherDomain
```

```Output
Id              : 0f0aec7b-ac5b-4f89-9fac-e9044ba5a309
DisplayName     : New app
AppId           : c678b75d-1012-4466-8655-1672192232b4
SignInAudience  : AzureADandPersonalMicrosoftAccount
PublisherDomain : M365B977454.onmicrosoft.com
```

### Example 2: Create with web redirect URIs

```powershell
$webApp = @{
  RedirectUris = @("https://myapp.com/auth/callback")
}

New-MgApplication -DisplayName "MyApp" -Web $webApp
```

### Example 3: Create with app roles

```powershell
$appRole = @{
  Id = [guid]::NewGuid().ToString()
  DisplayName = "Admin"
  Value = "admin"
  AllowedMemberTypes = @("User")
  Description = "Admin role"
  IsEnabled = $true
}

New-MgApplication -DisplayName "MyApp" -AppRoles @($appRole)
```

## Parameters

### -DisplayName

The display name for the application. Maximum length is 256 characters. Supports `$filter` (eq, ne, not, ge, le, in, startsWith, and eq on null values), `$search`, and `$orderby`.

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -Description

Free text field to provide a description of the application object to end users. The maximum allowed size is 1,024 characters. Supports `$filter` (eq, ne, not, ge, le, startsWith) and `$search`.

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -IdentifierUris

Also known as App ID URI. The identifierUris acts as the prefix for the scopes you reference in your API's code, and it must be globally unique across Microsoft Entra ID.

| | |
| --- | --- |
| **Type:** | System.String[] |
| **Mandatory:** | False |

### -SignInAudience

Specifies the Microsoft accounts that are supported for the current application. Possible values:

- `AzureADMyOrg` (default)
- `AzureADMultipleOrgs`
- `AzureADandPersonalMicrosoftAccount`
- `PersonalMicrosoftAccount`

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -Web

webApplication configuration for web applications.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphWebApplication |
| **Mandatory:** | False |

### -Spa

spaApplication configuration for single-page applications.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphSpaApplication |
| **Mandatory:** | False |

### -PublicClient

publicClientApplication configuration for public client applications.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphPublicClientApplication |
| **Mandatory:** | False |

### -AppRoles

The collection of roles defined for the application. With app role assignments, these roles can be assigned to users, groups, or service principals associated with other applications. Not nullable.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphAppRole[] |
| **Mandatory:** | False |

### -Api

apiApplication configuration.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApiApplication |
| **Mandatory:** | False |

### -RequiredResourceAccess

Specifies the resources that the application needs to access. This property also specifies the set of delegated permissions and application roles that it needs for each of those resources. No more than 50 resource services (APIs) can be configured.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphRequiredResourceAccess[] |
| **Mandatory:** | False |

### -KeyCredentials

The collection of key credentials associated with the application. Not nullable. Supports `$filter` (eq, not, ge, le).

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphKeyCredential[] |
| **Mandatory:** | False |

### -PasswordCredentials

The collection of password credentials associated with the application. Not nullable.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphPasswordCredential[] |
| **Mandatory:** | False |

### -Tags

Custom strings that can be used to categorize and identify the application. Not nullable. Strings added here also appear in the tags property of any associated service principals. Supports `$filter` (eq, not, ge, le, startsWith) and `$search`.

| | |
| --- | --- |
| **Type:** | System.String[] |
| **Mandatory:** | False |

### -GroupMembershipClaims

Configures the groups claim issued in a user or OAuth 2.0 access token. Possible values: `None`, `SecurityGroup`, `All`.

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -FederatedIdentityCredentials

Federated identities for applications. Supports `$expand` and `$filter` (startsWith, /$count eq 0, /$count ne 0).

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphFederatedIdentityCredential[] |
| **Mandatory:** | False |

### -DefaultRedirectUri

The default redirect URI for the application.

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -IsDeviceOnlyAuthSupported

Specifies whether this application supports device authentication without a user. The default is false.

| | |
| --- | --- |
| **Type:** | System.Management.Automation.SwitchParameter |
| **Mandatory:** | False |

### -IsFallbackPublicClient

Specifies the fallback application type as public client, such as an installed application running on a mobile device. The default value is false.

| | |
| --- | --- |
| **Type:** | System.Management.Automation.SwitchParameter |
| **Mandatory:** | False |

### -Notes

Notes relevant for the management of the application.

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -SamlMetadataUrl

The URL where the service exposes SAML metadata for federation. This property is valid only for single-tenant applications. Nullable.

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -TokenEncryptionKeyId

Specifies the keyId of a public key from the keyCredentials collection. When configured, Microsoft Entra ID encrypts all the tokens it emits by using the key this property points to.

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -UniqueName

The unique identifier that can be assigned to an application and used as an alternate key. Immutable. Read-only.

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -PublisherDomain

The verified publisher domain for the application. Read-only. Supports `$filter` (eq, ne, ge, le, startsWith).

| | |
| --- | --- |
| **Type:** | System.String |
| **Mandatory:** | False |

### -BodyParameter

Full application object. To construct, see NOTES section for BODYPARAMETER properties and create a hash table.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApplication |
| **Mandatory:** | True (in `Create` parameter set) |

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, -Confirm.

## Inputs

- **Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApplication**
- **System.Collections.IDictionary**

## Outputs

- **Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApplication**

## Notes

- The `AppId` is automatically assigned by Microsoft Entra ID and cannot be specified.
- `PublisherDomain` is read-only and automatically set.
- The cmdlet supports piping and common parameters (`-WhatIf`, `-Confirm`, `-Verbose`).
- Response headers can be captured using `-ResponseHeadersVariable`.

## Related Links

- [Get-MgApplication](https://learn.microsoft.com/powershell/module/microsoft.graph.applications/get-mgapplication)
- [Update-MgApplication](https://learn.microsoft.com/powershell/module/microsoft.graph.applications/update-mgapplication)
- [Remove-MgApplication](https://learn.microsoft.com/powershell/module/microsoft.graph.applications/remove-mgapplication)
- [New-MgBetaApplication](/en-us/powershell/module/Microsoft.Graph.Beta.Applications/New-MgBetaApplication?view=graph-powershell-beta)
- [Microsoft.Graph.Applications Module](https://learn.microsoft.com/powershell/module/microsoft.graph.applications)
