<#
.SYNOPSIS
    Load .env file from project root and expose values as $env: variables.
    Source this at the top of every script: . "$PSScriptRoot/../_common/Config.ps1"

    Scripts declare what they need via $script:RequiredVars before sourcing this file.
    Example:
        $script:RequiredVars = @('ENTRA_TENANT_ID', 'ENTRA_CLIENT_ID')
        . "$PSScriptRoot/../_common/Config.ps1"
#>

$projectRoot = Resolve-Path "$PSScriptRoot/../../"
$envFile     = Join-Path $projectRoot ".env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env not found at $envFile`nRun: cp .env.example .env  then fill in ENTRA_TENANT_ID"
    exit 1
}

# Load all key=value pairs into process environment
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) {
            $key   = $parts[0].Trim()
            $value = ($parts[1] -replace '\s*#.*$', '').Trim()
            [System.Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
}

# Only validate what THIS script actually needs (set $script:RequiredVars before sourcing)
if ($script:RequiredVars) {
    $missing = $script:RequiredVars | Where-Object {
        -not (Get-Item "env:$_" -ErrorAction SilentlyContinue)?.Value
    }
    if ($missing) {
        Write-Error "Required .env values not set: $($missing -join ', ')`nSee .env.example for which stage populates these."
        exit 1
    }
}

# SSL bypass for Nexus self-signed cert (set NEXUS_SKIP_SSL_VERIFY=true in .env)
if ($env:NEXUS_SKIP_SSL_VERIFY -eq 'true') {
    $PSDefaultParameterValues['Invoke-RestMethod:SkipCertificateCheck'] = $true
    $PSDefaultParameterValues['Invoke-WebRequest:SkipCertificateCheck']  = $true
}

# ── Set-EnvValue ──────────────────────────────────────────────────────────────
# Write a key=value pair back to the .env file and update the current session.
# Updates in place if the key already exists; appends if it does not.
# Usage: Set-EnvValue 'ENTRA_CLIENT_ID' $app.AppId
function Set-EnvValue {
    param([string]$Key, [string]$Value)
    $file    = Join-Path (Resolve-Path "$PSScriptRoot/../../") ".env"
    $content = Get-Content $file -Raw
    if ($content -match "(?m)^$Key=") {
        $content = $content -replace "(?m)^$Key=.*", "$Key=$Value"
    } else {
        $content = $content.TrimEnd() + "`n$Key=$Value`n"
    }
    Set-Content $file $content -NoNewline
    [System.Environment]::SetEnvironmentVariable($Key, $Value, 'Process')
    Write-Host "  .env updated: $Key" -ForegroundColor DarkGray
}
