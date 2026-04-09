param(
    [string]$Root = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

$topLevelMarkdown = @()
$topLevelMarkdown += Get-ChildItem -Path (Join-Path $Root "techniques") -File -Filter "*.md" -ErrorAction SilentlyContinue
$topLevelMarkdown += Get-ChildItem -Path (Join-Path $Root "reference") -File -Filter "*.md" -ErrorAction SilentlyContinue

foreach ($file in $topLevelMarkdown) {
    $path = $file.FullName
    $text = [System.IO.File]::ReadAllText($path)
    $lines = $text -split "`r?`n"

    if ($text -match "\[SKILL\.md\]\(SKILL\.md\)") {
        Add-Failure "$($file.Name): unresolved SKILL.md relative link"
    }

    if ($text -match "```hlsl") {
        Add-Failure "$($file.Name): legacy doc still contains ```hlsl fences"
    }

    if ($text -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
        Add-Failure "$($file.Name): contains control characters"
    }

    if ($lines.Length -gt 100 -and $text -notmatch "<!-- GENERATED:TOC:START -->") {
        Add-Failure "$($file.Name): long file missing generated TOC"
    }

    if ($text -notmatch "<!-- GENERATED:NOTICE:START -->") {
        Add-Failure "$($file.Name): missing execution-status notice"
    }
}

if (-not (Test-Path (Join-Path $Root "agents\openai.yaml"))) {
    Add-Failure "agents/openai.yaml is missing"
}

if (-not (Test-Path (Join-Path $Root "assets\templates\urp-unlit-material.shader"))) {
    Add-Failure "assets/templates/urp-unlit-material.shader is missing"
}

if (-not (Test-Path (Join-Path $Root "reference\pipeline\authoring-contract.md"))) {
    Add-Failure "reference/pipeline/authoring-contract.md is missing"
}

if ($failures.Count -gt 0) {
    Write-Host "Validation failed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Validation passed." -ForegroundColor Green
