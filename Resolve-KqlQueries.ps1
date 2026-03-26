<#
.SYNOPSIS
    Resolves .kql file references in Sentinel analytic rule JSON templates.

.DESCRIPTION
    Reads each JSON file under AnalyticRules/, looks for a "queryFile" property
    pointing to a .kql file in the same folder, reads that file, and injects the
    content into the "query" property (replacing @@QUERY_PLACEHOLDER@@).
    Overwrites JSON files in-place so they are ready for ARM deployment.

.PARAMETER InputPath
    Root folder containing analytic rule JSON files. Default: AnalyticRules
#>
param(
    [string]$InputPath = (Join-Path $PSScriptRoot "AnalyticRules")
)

$jsonFiles = Get-ChildItem -Path $InputPath -Filter "*.json" -Recurse
$resolvedCount = 0

foreach ($file in $jsonFiles) {
    $json = Get-Content -Path $file.FullName -Raw
    $obj  = $json | ConvertFrom-Json -Depth 20
    $modified = $false

    # Walk resources looking for a queryFile property
    foreach ($resource in $obj.resources) {
        $props = $resource.properties
        if ($null -ne $props -and $null -ne $props.queryFile) {
            $kqlPath = Join-Path $file.DirectoryName $props.queryFile

            if (-not (Test-Path $kqlPath)) {
                Write-Error "KQL file not found: $kqlPath (referenced by $($file.Name))"
                continue
            }

            $kqlContent = (Get-Content -Path $kqlPath -Raw).TrimEnd()

            # Escape for JSON string value: newlines -> \n
            $escaped = $kqlContent -replace '\\', '\\' -replace '"', '\"' -replace "`r`n", '\n' -replace "`n", '\n'

            # Replace the placeholder in the raw JSON text
            $json = $json -replace '@@QUERY_PLACEHOLDER@@', $escaped

            # Remove the queryFile helper property (not part of the ARM schema)
            $json = $json -replace '(?m)^\s*"queryFile"\s*:\s*"[^"]*"\s*,?\s*\r?\n', ''

            $modified = $true
            Write-Host "Resolved query for $($file.Name) from $($props.queryFile)"
        }
    }

    if ($modified) {
        Set-Content -Path $file.FullName -Value $json -NoNewline
        $resolvedCount++
        Write-Host "Updated in-place: $($file.FullName)"
    }
}

Write-Host "Resolved $resolvedCount file(s)."
