<#
.SYNOPSIS
    Add required Microsoft Graph API permissions to the Nexus Entra app
    and grant admin consent for all permissions.

.NOTES
    Admin Guide: §2.10.2
    Must run AFTER 01-Register-NexusApp.ps1

    11 permissions total — the admin guide §2.10.2 lists 10.
    Application.ReadWrite.All (Application type) is missing from the guide.

    Application: AiEnterpriseInteraction.Read.All, AppCatalog.ReadWrite.All,
                 Application.ReadWrite.All (*), ExternalConnection.ReadWrite.All,
                 ExternalItem.ReadWrite.All, Group.Read.All, User.Read.All
    Delegated:   ExternalItem.Read.All, Files.Read.All, Sites.Read.All, User.Read
    (*) Not in admin guide — required.

    Idempotent: safe to re-run. Existing grants are detected and skipped.

    Authentication: interactive browser login (delegated admin required for admin consent).
    If you just ran entra/01, MSAL has the token cached — no browser popup here.
#>

$script:RequiredVars = @('ENTRA_TENANT_ID', 'ENTRA_CLIENT_ID')
. "$PSScriptRoot/../_common/Config.ps1"

# ── Auth ──────────────────────────────────────────────────────────────────────
Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All" -NoWelcome

# ── Resolve Nexus app ─────────────────────────────────────────────────────────
$clientId = $env:ENTRA_CLIENT_ID
$app = Get-MgApplication -Filter "appId eq '$clientId'"
if (-not $app) { throw "App with Client ID $clientId not found in Entra" }

# Service principal is needed for consent grants (separate object from the app registration)
$nexusSp = Get-MgServicePrincipal -Filter "appId eq '$clientId'"
if (-not $nexusSp) {
    Write-Host "Creating service principal for Nexus app..." -ForegroundColor Cyan
    $nexusSp = New-MgServicePrincipal -AppId $clientId
}

# ── Resolve Microsoft Graph service principal ─────────────────────────────────
$graphSpAppId = "00000003-0000-0000-c000-000000000000"
$graphSp = Get-MgServicePrincipal -Filter "appId eq '$graphSpAppId'"
if (-not $graphSp) { throw "Microsoft Graph service principal not found in tenant" }

Write-Host ""
Write-Host "App:         $($app.DisplayName)  ($clientId)" -ForegroundColor DarkGray
Write-Host "App SP ID:   $($nexusSp.Id)" -ForegroundColor DarkGray
Write-Host "Graph SP ID: $($graphSp.Id)" -ForegroundColor DarkGray

# ── Required permissions ──────────────────────────────────────────────────────
$requiredPermissions = @(
    @{ Name = "AiEnterpriseInteraction.Read.All"; Type = "Role"  }
    @{ Name = "AppCatalog.ReadWrite.All";          Type = "Role"  }
    @{ Name = "Application.ReadWrite.All";         Type = "Role"  }  # Not in admin guide §2.10.2 — required
    @{ Name = "ExternalConnection.ReadWrite.All";  Type = "Role"  }
    @{ Name = "ExternalItem.ReadWrite.All";        Type = "Role"  }
    @{ Name = "Group.Read.All";                    Type = "Role"  }
    @{ Name = "User.Read.All";                     Type = "Role"  }
    @{ Name = "ExternalItem.Read.All";             Type = "Scope" }
    @{ Name = "Files.Read.All";                    Type = "Scope" }
    @{ Name = "Sites.Read.All";                    Type = "Scope" }
    @{ Name = "User.Read";                         Type = "Scope" }
)

# ── Step 1: Resolve permission IDs against the Graph service principal ────────
Write-Host ""
Write-Host "Resolving permissions against Microsoft Graph SP..." -ForegroundColor Cyan

$rolePermissions  = [System.Collections.Generic.List[hashtable]]::new()
$scopePermissions = [System.Collections.Generic.List[hashtable]]::new()

foreach ($perm in $requiredPermissions) {
    if ($perm.Type -eq "Role") {
        $appRole = $graphSp.AppRoles | Where-Object Value -eq $perm.Name
        if (-not $appRole) {
            Write-Warning "AppRole '$($perm.Name)' not found in Graph SP — skipping"
            continue
        }
        $rolePermissions.Add(@{ Id = $appRole.Id; Name = $perm.Name })
        Write-Host "  [Role]  $($perm.Name)" -ForegroundColor DarkGray
    } else {
        $scope = $graphSp.Oauth2PermissionScopes | Where-Object Value -eq $perm.Name
        if (-not $scope) {
            Write-Warning "Scope '$($perm.Name)' not found in Graph SP — skipping"
            continue
        }
        $scopePermissions.Add(@{ Id = $scope.Id; Name = $perm.Name })
        Write-Host "  [Scope] $($perm.Name)" -ForegroundColor DarkGray
    }
}

# ── Step 2: Update app manifest (RequiredResourceAccess) ─────────────────────
Write-Host ""
Write-Host "Updating app manifest..." -ForegroundColor Cyan

$resourceAccess = @(
    ($rolePermissions  | ForEach-Object { @{ Id = $_.Id; Type = "Role"  } })
    ($scopePermissions | ForEach-Object { @{ Id = $_.Id; Type = "Scope" } })
)

Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess @(
    @{
        ResourceAppId  = $graphSpAppId
        ResourceAccess = $resourceAccess
    }
)
Write-Host "App manifest updated." -ForegroundColor Green

# ── Step 3: Admin consent — Application permissions ───────────────────────────
Write-Host ""
Write-Host "Granting admin consent for Application permissions..." -ForegroundColor Cyan

$existingRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $nexusSp.Id

foreach ($r in $rolePermissions) {
    if ($existingRoleAssignments | Where-Object AppRoleId -eq $r.Id) {
        Write-Host "  [SKIP]  $($r.Name) — already granted" -ForegroundColor DarkGray
        continue
    }
    try {
        New-MgServicePrincipalAppRoleAssignment `
            -ServicePrincipalId $nexusSp.Id `
            -PrincipalId        $nexusSp.Id `
            -ResourceId         $graphSp.Id `
            -AppRoleId          $r.Id | Out-Null
        Write-Host "  [GRANT] $($r.Name)" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to grant $($r.Name): $($_.Exception.Message)"
    }
}

# ── Step 4: Admin consent — Delegated permissions ─────────────────────────────
Write-Host ""
Write-Host "Granting admin consent for Delegated permissions..." -ForegroundColor Cyan

$scopeString    = ($scopePermissions | ForEach-Object { $_.Name }) -join " "
$existingGrant  = Get-MgOauth2PermissionGrant `
    -Filter "clientId eq '$($nexusSp.Id)' and resourceId eq '$($graphSp.Id)'" `
    -ErrorAction SilentlyContinue

try {
    if ($existingGrant) {
        Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $existingGrant.Id -Scope $scopeString -ErrorAction Stop
        Write-Host "  [UPDATE] Delegated grant updated." -ForegroundColor Green
    } else {
        New-MgOauth2PermissionGrant `
            -ClientId    $nexusSp.Id `
            -ConsentType "AllPrincipals" `
            -ResourceId  $graphSp.Id `
            -Scope       $scopeString `
            -ErrorAction Stop | Out-Null
        Write-Host "  [GRANT] Delegated consent granted." -ForegroundColor Green
    }
} catch {
    Write-Host "  [FAIL] Delegated grant failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Grant manually: portal.azure.com → App registrations → $($env:ENTRA_APP_NAME) → API permissions → Grant admin consent" -ForegroundColor Yellow
}

Write-Host "  Scopes: $scopeString" -ForegroundColor DarkGray

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ("─" * 60)
Write-Host "$($rolePermissions.Count) Application + $($scopePermissions.Count) Delegated = $($rolePermissions.Count + $scopePermissions.Count) permissions — done." -ForegroundColor Green
Write-Host ""
Write-Host "Verify: portal.azure.com → App registrations → $($env:ENTRA_APP_NAME) → API permissions" -ForegroundColor DarkGray
Write-Host "        All entries should show 'Granted for <tenant>'" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Run next: scripts/entra/03-New-ClientSecret.ps1" -ForegroundColor Cyan
