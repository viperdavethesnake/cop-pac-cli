<#
.SYNOPSIS
    Create a client secret for the Nexus Entra app.
    Outputs the secret value — update .env immediately, it will not be shown again.

.NOTES
    Admin Guide: §2.10.2
    Max secret expiry: 2 years (730 days). Set a calendar reminder.
    Run AFTER 01-Register-NexusApp.ps1

    Authentication: interactive browser login (cached from entra/01 — no popup expected).
    After this script writes ENTRA_CLIENT_SECRET to .env, all remaining scripts authenticate
    non-interactively via service principal — no browser required from this point on.
#>

$script:RequiredVars = @('ENTRA_TENANT_ID', 'ENTRA_CLIENT_ID')
. "$PSScriptRoot/../_common/Config.ps1"

Connect-MgGraph -TenantId $env:ENTRA_TENANT_ID -Scopes "Application.ReadWrite.All" -NoWelcome

$clientId = $env:ENTRA_CLIENT_ID
if (-not $clientId) { throw "ENTRA_CLIENT_ID not set in .env" }

$app = Get-MgApplication -Filter "appId eq '$clientId'"
if (-not $app) { throw "App with Client ID $clientId not found" }

# ── Create secret ─────────────────────────────────────────────────────────────
$expiryDays = 365   # TODO: make configurable via .env or param

$secretParams = @{
    PasswordCredential = @{
        DisplayName = "$($env:ENTRA_APP_NAME)-$(Get-Date -Format 'yyyyMMdd')"
        EndDateTime = (Get-Date).AddDays($expiryDays)
    }
}

$secret = Add-MgApplicationPassword -ApplicationId $app.Id @secretParams

Set-EnvValue 'ENTRA_CLIENT_SECRET' $secret.SecretText

Write-Host ""
Write-Host "Client secret created and written to .env." -ForegroundColor Green
Write-Host ""
Write-Host "  Value : $($secret.SecretText)" -ForegroundColor Cyan
Write-Host "  Expires: $($secret.EndDateTime)"
Write-Host ""
Write-Host "Store this value in your password manager — it cannot be retrieved again from Entra." -ForegroundColor Yellow
Write-Host "Run next: scripts/nexus/01-Configure-StoragePlugin.ps1 (once Nexus VM is deployed)" -ForegroundColor Cyan
