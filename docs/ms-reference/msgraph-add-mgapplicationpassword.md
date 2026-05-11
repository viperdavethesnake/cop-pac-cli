# Add-MgApplicationPassword
Source: https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.applications/add-mgapplicationpassword
Fetched: 2026-05-05

---

- Module: [Microsoft.Graph.Applications Module](./)

Adds a strong password or secret to an application. You can also add passwords while creating the application.

> **Note:** To view the beta release of this cmdlet, view [Add-MgBetaApplicationPassword](/en-us/powershell/module/Microsoft.Graph.Beta.Applications/Add-MgBetaApplicationPassword?view=graph-powershell-beta)

## Syntax

### AddExpanded (Default)

```powershell
Add-MgApplicationPassword
    -ApplicationId <string>
    [-ResponseHeadersVariable <string>]
    [-AdditionalProperties <hashtable>]
    [-PasswordCredential <IMicrosoftGraphPasswordCredential>]
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

### Add

```powershell
Add-MgApplicationPassword
    -ApplicationId <string>
    -BodyParameter <IPaths141Ryo0ApplicationsApplicationIdMicrosoftGraphAddpasswordPostRequestbodyContentApplicationJsonSchema>
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

### AddViaIdentityExpanded

```powershell
Add-MgApplicationPassword
    -InputObject <IApplicationsIdentity>
    [-ResponseHeadersVariable <string>]
    [-AdditionalProperties <hashtable>]
    [-PasswordCredential <IMicrosoftGraphPasswordCredential>]
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

### AddViaIdentity

```powershell
Add-MgApplicationPassword
    -InputObject <IApplicationsIdentity>
    -BodyParameter <IPaths141Ryo0ApplicationsApplicationIdMicrosoftGraphAddpasswordPostRequestbodyContentApplicationJsonSchema>
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

Adds a strong password or secret to an application. You can also add passwords while creating the application.

## Permissions

| Permission type | Permissions (from least to most privileged) |
| --- | --- |
| Delegated (work or school account) | Application.ReadWrite.All, Directory.ReadWrite.All |
| Delegated (personal Microsoft account) | Application.ReadWrite.All |
| Application | Application.ReadWrite.OwnedBy, Directory.ReadWrite.All, Application.ReadWrite.All |

## Examples

### Example 1: Add a password credential to an application with a six month expiry

```powershell
Connect-MgGraph -Scopes 'Application.ReadWrite.All'

$appObjectId = 'eaf1e531-0d58-4874-babe-b9a9f436e6c3'

$passwordCred = @{
   displayName = 'Created in PowerShell'
   endDateTime = (Get-Date).AddMonths(6)
}

$secret = Add-MgApplicationPassword -applicationId $appObjectId -PasswordCredential $passwordCred
$secret | Format-List
```

```Output
CustomKeyIdentifier  :
DisplayName          : Created in PowerShell
EndDateTime          : 26/11/2022 12:03:31 pm
Hint                 : Q_e
KeyId                : c82bb763-741b-4575-9d9d-df7e766f6999
SecretText           : <redacted — example value from Microsoft docs>
StartDateTime        : 26/5/2022 1:03:31 pm
AdditionalProperties : {[@odata.context,
                       https://graph.microsoft.com/v1.0/$metadata#microsoft.graph.passwordCredential]}
```

Add a password to an application that expires in six months from the current date.

### Example 2: Add a password credential to an application with a start date

```powershell
Connect-MgGraph -Scopes 'Application.ReadWrite.All'

$appObjectId = 'eaf1e531-0d58-4874-babe-b9a9f436e6c3'

$startDate = (Get-Date).AddDays(1).Date
$endDate = $startDate.AddMonths(6)

$passwordCred = @{
   displayName = 'Created in PowerShell'
   startDateTime = $startDate
   endDateTime = $endDate
}

$secret = Add-MgApplicationPassword -applicationId $appObjectId -PasswordCredential $passwordCred
$secret | Format-List
```

```Output
CustomKeyIdentifier  :
DisplayName          : Created in PowerShell
EndDateTime          : 26/11/2022 1:00:00 pm
Hint                 : TiA
KeyId                : 082bf20f-63d6-4970-bb4e-55e504f50d8b
SecretText           : <redacted — example value from Microsoft docs>
StartDateTime        : 26/5/2022 2:00:00 pm
AdditionalProperties : {[@odata.context,
                       https://graph.microsoft.com/v1.0/$metadata#microsoft.graph.passwordCredential]}
```

Add a password to an application that becomes valid at 12:00 am the next day and is valid for six months.

Use `$secret.StartDateTime.ToLocalTime()` to convert the returned dates from UTC to the local timezone.

## Parameters

### -ApplicationId

The unique identifier of application.

| | |
| --- | --- |
| **Type:** | System.String |
| **Aliases:** | ObjectId |
| **Mandatory:** | True (in `AddExpanded`, `Add` parameter sets) |
| **Supports wildcards:** | False |

### -PasswordCredential

passwordCredential. To construct, see NOTES section for PASSWORDCREDENTIAL properties and create a hash table.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IMicrosoftGraphPasswordCredential |
| **Mandatory:** | False |

### -InputObject

Identity Parameter. To construct, see NOTES section for INPUTOBJECT properties and create a hash table.

| | |
| --- | --- |
| **Type:** | Microsoft.Graph.PowerShell.Models.IApplicationsIdentity |
| **Mandatory:** | True (in `AddViaIdentityExpanded`, `AddViaIdentity` parameter sets) |

### -BodyParameter

Full request body parameter. To construct, see NOTES section for BODYPARAMETER properties and create a hash table.

| | |
| --- | --- |
| **Type:** | IPaths141Ryo0...Schema |
| **Mandatory:** | True (in `AddViaIdentity`, `Add` parameter sets) |

### -AdditionalProperties

Additional Parameters.

| | |
| --- | --- |
| **Type:** | System.Collections.Hashtable |
| **Mandatory:** | False |

### -ResponseHeadersVariable

Optional Response Headers Variable.

| | |
| --- | --- |
| **Type:** | System.String |
| **Aliases:** | RHV |
| **Mandatory:** | False |

### -Break

Wait for .NET debugger to attach.

| | |
| --- | --- |
| **Type:** | System.Management.Automation.SwitchParameter |
| **Default value:** | False |
| **Mandatory:** | False |

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

| | |
| --- | --- |
| **Type:** | System.Management.Automation.SwitchParameter |
| **Aliases:** | wi |
| **Mandatory:** | False |

### -Confirm

Prompts you for confirmation before running the cmdlet.

| | |
| --- | --- |
| **Type:** | System.Management.Automation.SwitchParameter |
| **Aliases:** | cf |
| **Mandatory:** | False |

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, -WarningVariable. For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## Inputs

- **Microsoft.Graph.PowerShell.Models.IApplicationsIdentity**
- **Microsoft.Graph.PowerShell.Models.IPaths141Ryo0...Schema**
- **System.Collections.IDictionary**

## Outputs

- **Microsoft.Graph.PowerShell.Models.IMicrosoftGraphPasswordCredential**

## Notes

### PASSWORDCREDENTIAL properties (hash table)

- **[CustomKeyIdentifier `<Byte[]>`]**: Do not use.
- **[DisplayName `<String>`]**: Friendly name for the password. Optional.
- **[EndDateTime `<DateTime?>`]**: The date and time at which the password expires represented using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. Optional.
- **[Hint `<String>`]**: Contains the first three characters of the password. Read-only.
- **[KeyId `<String>`]**: The unique identifier for the password.
- **[SecretText `<String>`]**: Read-only; Contains the strong passwords generated by Microsoft Entra ID that are 16-64 characters in length. The generated password value is only returned during the initial POST request to addPassword. There is no way to retrieve this password in the future.
- **[StartDateTime `<DateTime?>`]**: The date and time at which the password becomes valid. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. Optional.

### INPUTOBJECT properties (IApplicationsIdentity)

- **[AppId `<String>`]**: Alternate key of application
- **[ApplicationId `<String>`]**: The unique identifier of application
- **[ServicePrincipalId `<String>`]**: The unique identifier of servicePrincipal
- **[UserId `<String>`]**: The unique identifier of user
- *(and many more identity parameters)*

## Related Links

- [Add-MgApplicationPassword](/en-us/powershell/module/microsoft.graph.applications/add-mgapplicationpassword)
- [Graph API Reference](/en-us/graph/api/application-addpassword?view=graph-rest-1.0)
