param(
    [string]$Root = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Slug {
    param([string]$Text)

    $slug = $Text.ToLowerInvariant()
    $slug = [regex]::Replace($slug, "[^a-z0-9\-\s]", "")
    $slug = [regex]::Replace($slug, "\s+", "-")
    $slug = [regex]::Replace($slug, "-{2,}", "-")
    return $slug.Trim("-")
}

function Get-TocLines {
    param([string[]]$Lines)

    $toc = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        if ($line -match "^(##|###)\s+(.+)$") {
            $hashes = $matches[1]
            $title = $matches[2].Trim()
            if ($title -eq "Table of Contents") {
                continue
            }

            $indent = if ($hashes.Length -eq 2) { "" } else { "  " }
            $toc.Add("$indent- [$title](#$(Get-Slug $title))")
        }
    }

    return $toc
}

function Get-NoticeLines {
    param([string]$Kind)

    if ($Kind -eq "techniques") {
        return @(
            "> Execution status: prototype algorithm reference.",
            "> Treat code blocks in this file as GLSL-style algorithm notes unless a section explicitly says `Unity URP Executable`.",
            "> For runnable Unity output, start from [the authoring contract](../reference/pipeline/authoring-contract.md) and the templates in [assets/templates](../assets/templates)."
        )
    }

    return @(
        "> Execution status: legacy deep reference.",
        "> Treat code blocks in this file as algorithm-first GLSL notes unless a section explicitly says `Unity URP Executable`.",
        "> For runnable Unity output, start from [the authoring contract](pipeline/authoring-contract.md) and the templates in [assets/templates](../assets/templates)."
    )
}

function Get-TitleFromName {
    param([string]$FileName)

    $title = ($FileName -replace "\.md$", "") -replace "-", " "
    $textInfo = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo
    return $textInfo.ToTitleCase($title)
}

$targets = @(
    @{ Path = Join-Path $Root "techniques"; Kind = "techniques" },
    @{ Path = Join-Path $Root "reference"; Kind = "reference" }
)

foreach ($target in $targets) {
    if (-not (Test-Path $target.Path)) {
        continue
    }

    Get-ChildItem -Path $target.Path -File -Filter "*.md" | ForEach-Object {
        $path = $_.FullName
        $text = [System.IO.File]::ReadAllText($path)

        $text = $text -replace "\[SKILL\.md\]\(SKILL\.md\)", "[SKILL.md](../SKILL.md)"
        $text = $text -replace "```hlsl", "```glsl"
        $text = [regex]::Replace($text, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "")
        $text = $text -replace "SAMPLE_TEXTURE2D\.#", "SAMPLE_TEXTURE2D.`r`n`r`n#"
        $text = $text -replace '(?m)^`csharp\s*$', '```csharp'
        $text = $text -replace '(?m)^`\s*$', '```'
        $text = $text -replace 'Template### Step', "Template`r`n`r`n### Step"
        $text = $text -replace '(?s)<!-- GENERATED:NOTICE:START -->.*?<!-- GENERATED:NOTICE:END -->\r?\n?', ''
        $text = $text -replace '(?s)<!-- GENERATED:TOC:START -->.*?<!-- GENERATED:TOC:END -->\r?\n?', ''

        $lines = $text -split "`r?`n"
        $headingIndex = -1
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match "^# ") {
                $headingIndex = $i
                break
            }
        }

        if ($headingIndex -lt 0) {
            $fallbackTitle = Get-TitleFromName $_.Name
            $lines = @("# $fallbackTitle", "") + $lines
            $headingIndex = 0
            $text = [string]::Join([Environment]::NewLine, $lines)
        }

        $lineCount = $lines.Length
        $newLines = New-Object System.Collections.Generic.List[string]

        for ($i = 0; $i -le $headingIndex; $i++) {
            $newLines.Add($lines[$i])
        }

        $newLines.Add("")
        $newLines.Add("<!-- GENERATED:NOTICE:START -->")
        foreach ($noticeLine in (Get-NoticeLines $target.Kind)) {
            $newLines.Add($noticeLine)
        }
        $newLines.Add("<!-- GENERATED:NOTICE:END -->")
        $newLines.Add("")

        if ($lineCount -gt 100) {
            $newLines.Add("<!-- GENERATED:TOC:START -->")
            $newLines.Add("## Table of Contents")
            $newLines.Add("")
            foreach ($tocLine in (Get-TocLines $lines)) {
                $newLines.Add($tocLine)
            }
            $newLines.Add("<!-- GENERATED:TOC:END -->")
            $newLines.Add("")
        }

        for ($i = $headingIndex + 1; $i -lt $lines.Length; $i++) {
            $newLines.Add($lines[$i])
        }

        $content = [string]::Join([Environment]::NewLine, $newLines)
        [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
    }
}
