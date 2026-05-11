<#
.SYNOPSIS
    Create data ingestion rules in Nexus via REST API.
    Rules filter which files get ingested into Copilot.

.NOTES
    Admin Guide: §2.8.4
    Supported file extensions: .docx, .doc, .txt, .pdf, .jpeg, .jpg, .jpe,
                                .jfif, .png, .dwg (plus custom extensions)
    Available criteria: File Extension, File Path pattern, File Size,
                        File Timestamps, File Modified By
    Note: File Ownership criterion is NOT supported.
#>

. "$PSScriptRoot/../_common/Config.ps1"

$nexusBase = "https://$($env:NEXUS_IP)"

# ── Auth ──────────────────────────────────────────────────────────────────────
$loginBody = @{ username = $env:NEXUS_ADMIN_USER; password = $env:NEXUS_ADMIN_PASSWORD } | ConvertTo-Json
$session   = Invoke-RestMethod -Uri "$nexusBase/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$headers   = @{ Authorization = "Bearer $($session.token)" }

# ── Define rules ──────────────────────────────────────────────────────────────
# TODO: Make rules configurable via a JSON input file rather than hard-coding
$rules = @(
    @{
        name        = "office-and-pdf"
        description = "Include Office documents and PDFs"
        criteria    = @(
            @{
                type       = "FileExtension"
                extensions = @(".docx", ".doc", ".pdf", ".txt")
                inclusive  = $true
            }
        )
    }
)

foreach ($rule in $rules) {
    $body   = $rule | ConvertTo-Json -Depth 5
    # TODO: Confirm endpoint path
    $result = Invoke-RestMethod -Uri "$nexusBase/api/rules" `
        -Method Post -Body $body -ContentType "application/json" -Headers $headers
    Write-Host "Rule created: $($rule.name) (ID: $($result.id))" -ForegroundColor Green
}
