# Microsoft Power Platform CLI connector command group
Source: https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/connector
Fetched: 2026-05-05

---

# Microsoft Power Platform CLI connector command group

Commands for working with Power Platform Connectors.

## Commands

| Command | Description |
| --- | --- |
| pac connector create | Creates a new row in the Connector table in Dataverse. |
| pac connector download | Download a Connector's OpenApiDefinition and API Properties file |
| pac connector init | Initializes a new API Properties file for a Connector. |
| pac connector list | List the Connectors registered in Dataverse. |
| pac connector update | Updates a Connector Entity in Dataverse. |

---

## pac connector create

Creates a new row in the Connector table in Dataverse.

### Examples

#### Basic connector creation in current environment

This example creates a connector in the environment of your currently active auth profile.

```powershell
pac connector create `
  --api-definition-file ./apiDefinition.json `
  --api-properties-file ./apiProperties.json
```

#### Basic connector creation in specified environment

This example creates a connector in the specified environment.

```powershell
pac connector create `
  --api-definition-file ./apiDefinition.json `
  --api-properties-file ./apiProperties.json
  --environment 00000000-0000-0000-0000-000000000000
```

### Optional Parameters for connector create

#### `--api-definition-file` / `-df`

The filename and path to read the Connector's OpenApiDefinition.

#### `--api-properties-file` / `-pf`

The filename and path to read the Connector's API Properties file.

#### `--environment` / `-env`

Specifies the target Dataverse. The value may be a Guid or absolute https URL. When not specified, the active organization selected for the current auth profile will be used.

#### `--icon-file` / `-if`

The filename and path to and Icon .png file.

#### `--script-file` / `-sf`

The filename and path to a Script .csx file.

#### `--settings-file`

The filename and path Connector Settings file.

#### `--solution-unique-name` / `-sol`

The unique name of the solution to add the connector to.

---

## pac connector download

Download a Connector's OpenApiDefinition and API Properties file.

### Examples

#### Basic connector download

This example downloads the specified connector to the current directory.

```powershell
pac connector download `
  --connector-id 00000000-0000-0000-0000-000000000000
```

#### Basic connector download from specified environment

This example downloads the specified connector from the specified environment to the current directory.

```powershell
pac connector download `
  --connector-id 00000000-0000-0000-0000-000000000000 `
  --environment 00000000-0000-0000-0000-000000000000
```

#### Basic connector download from specified environment to the specified directory

This example downloads the specified connector from the specified environment to the specified directory.

```powershell
pac connector download `
  --connector-id 00000000-0000-0000-0000-000000000000 `
  --environment 00000000-0000-0000-0000-000000000000 `
  --outputDirectory "contoso_Connector"
```

### Required Parameters for connector download

#### `--connector-id` / `-id`

The ID of the Connector.

> **Note:** The Connector ID must be a valid Guid.

### Optional Parameters for connector download

#### `--environment` / `-env`

Specifies the target Dataverse. The value may be a Guid or absolute https URL. When not specified, the active organization selected for the current auth profile will be used.

#### `--outputDirectory` / `-o`

Output directory.

---

## pac connector init

Initializes a new API Properties file for a Connector.

### Example

#### Connector init with output directory and connection template for Microsoft Entra ID OAuth authentication

This example initializes a connector in the current directory.

```powershell
pac connector init `
  --connection-template "OAuthAAD" `
  --generate-script-file `
  --generate-settings-file `
  --outputDirectory "contoso_Connector"
```

### Optional Parameters for connector init

#### `--connection-template` / `-ct`

Generate an initial Connection Parameters set with the specified template.

Use one of these values:

- `NoAuth`
- `BasicAuth`
- `ApiKey`
- `OAuthGeneric`
- `OAuthAAD`

#### `--generate-script-file`

Generate an initial Connector Script file. This parameter requires no value — it's a switch.

#### `--generate-settings-file`

Generate an initial Connector Settings file. This parameter requires no value — it's a switch.

#### `--outputDirectory` / `-o`

Output directory.

---

## pac connector list

List the Connectors registered in Dataverse.

### Examples

#### List connectors in current environment

This example lists all the connectors in the environment of your currently active auth profile.

```powershell
pac connector list
```

#### List connectors in specified environment

This example lists all the connectors in the specified environment.

```powershell
pac connector list `
  --environment 00000000-0000-0000-0000-000000000000
```

### Optional Parameters for connector list

#### `--environment` / `-env`

Specifies the target Dataverse. The value may be a Guid or absolute https URL. When not specified, the active organization selected for the current auth profile will be used.

#### `--json`

Returns the output of the command as a JSON formatted string.

### Remarks

Only solution-aware connectors are shown. When your connector isn't in this command's response, it's probably because your connector isn't solution-aware.

---

## pac connector update

Updates a Connector Entity in Dataverse.

### Examples

#### Basic connector update in current environment

This example updates a connector in the environment of your currently active auth profile.

```powershell
pac connector update `
  --api-definition-file ./apiDefinition.json
```

#### Basic connector update in specified environment

This example updates a connector in the specified environment.

```powershell
pac connector update `
  --api-definition-file ./apiDefinition.json `
  --environment 00000000-0000-0000-0000-000000000000
```

### Optional Parameters for connector update

#### `--api-definition-file` / `-df`

The filename and path to read the Connector's OpenApiDefinition.

#### `--api-properties-file` / `-pf`

The filename and path to read the Connector's API Properties file.

#### `--connector-id` / `-id`

The ID of the Connector.

> **Note:** The Connector ID must be a valid Guid.

#### `--environment` / `-env`

Specifies the target Dataverse. The value may be a Guid or absolute https URL. When not specified, the active organization selected for the current auth profile will be used.

#### `--icon-file` / `-if`

The filename and path to and Icon .png file.

#### `--script-file` / `-sf`

The filename and path to a Script .csx file.

#### `--settings-file`

The filename and path Connector Settings file.

#### `--solution-unique-name` / `-sol`

The unique name of the solution to add the connector to.

## See also

- [Microsoft Power Platform CLI Command Groups](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/)
- [Microsoft Power Platform CLI overview](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction)
