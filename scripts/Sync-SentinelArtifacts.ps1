param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$SourceRoot,
    [string]$DeployRoot,
    [string]$BaseCommit,
    [string]$HeadCommit = 'HEAD',
    [switch]$RebuildAll
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SourceRoot) {
    $SourceRoot = Join-Path $RepositoryRoot 'src\AnalyticRules'
}

if (-not $DeployRoot) {
    $DeployRoot = Join-Path $RepositoryRoot 'AnalyticRules'
}

function Get-NormalizedRelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    return [System.IO.Path]::GetRelativePath($BasePath, $TargetPath).Replace('\', '/')
}

function Escape-BicepString {
    param([string]$Value)

    return ($Value -replace "'", "''") -replace "`r", '\r' -replace "`n", '\n'
}

function ConvertTo-BicepMultilineString {
    param([string]$Value)

    if ($Value.Contains("'''")) {
        throw 'KQL query contains triple single quotes, which are not supported by the generator.'
    }

    return "'''`n$Value`n'''"
}

function Get-SourceDetectionPaths {
    if ($RebuildAll -or [string]::IsNullOrWhiteSpace($BaseCommit) -or $BaseCommit -eq '0000000000000000000000000000000000000000') {
        return Get-ChildItem -Path $SourceRoot -Recurse -Filter metadata.bicep |
            ForEach-Object { Get-NormalizedRelativePath -BasePath $SourceRoot -TargetPath $_.DirectoryName } |
            Sort-Object -Unique
    }

    $changedFiles = git diff --name-only $BaseCommit $HeadCommit -- src/AnalyticRules

    if (-not $changedFiles) {
        return @()
    }

    return $changedFiles |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object {
            $absolutePath = Join-Path $RepositoryRoot $_
            $absoluteDirectory = Split-Path -Parent $absolutePath
            if ([string]::IsNullOrWhiteSpace($absoluteDirectory)) {
                return
            }

            Get-NormalizedRelativePath -BasePath $SourceRoot -TargetPath $absoluteDirectory
        } |
        Where-Object { $_ -and $_ -ne '.' } |
        Sort-Object -Unique
}

function Get-GeneratedRuleContent {
    param(
        [string]$DetectionRelativePath,
        [pscustomobject]$Metadata,
        [string]$QueryText
    )

    if ($Metadata.PSObject.Properties.Name -contains 'query') {
        throw "Source metadata for '$DetectionRelativePath' must not define a query property. The query must stay in query.kql."
    }

    foreach ($requiredProperty in @('ruleName', 'displayName')) {
        if (-not ($Metadata.PSObject.Properties.Name -contains $requiredProperty)) {
            throw "Source metadata for '$DetectionRelativePath' is missing required property '$requiredProperty'."
        }
    }

    $ruleProperties = [ordered]@{}
    foreach ($property in $Metadata.PSObject.Properties) {
        if ($property.Name -in @('ruleName', 'displayName')) {
            continue
        }

        $ruleProperties[$property.Name] = $property.Value
    }

    $escapedRuleName = Escape-BicepString $Metadata.ruleName
    $escapedDisplayName = Escape-BicepString $Metadata.displayName
    $rulePropertiesJson = ConvertTo-Json -InputObject $ruleProperties -Depth 100 -Compress
    $escapedRulePropertiesJson = Escape-BicepString $rulePropertiesJson
    $inlineQuery = ConvertTo-BicepMultilineString -Value $QueryText
    $sourceMetadataPath = Get-NormalizedRelativePath -BasePath $RepositoryRoot -TargetPath (Join-Path $SourceRoot (Join-Path $DetectionRelativePath 'metadata.bicep'))
    $sourceQueryPath = Get-NormalizedRelativePath -BasePath $RepositoryRoot -TargetPath (Join-Path $SourceRoot (Join-Path $DetectionRelativePath 'query.kql'))

    return @"
// Generated file. Do not edit directly.
// Source metadata: $sourceMetadataPath
// Source query: $sourceQueryPath

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var ruleName = '$escapedRuleName'
var ruleDisplayName = '$escapedDisplayName'
var ruleProperties = json('$escapedRulePropertiesJson')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspace
}

resource analyticRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  scope: logAnalyticsWorkspace
  name: ruleName
  kind: 'Scheduled'
  properties: union(ruleProperties, {
                displayName: '`${displayNamePrefix}`${ruleDisplayName}'
    query: $inlineQuery
  })
}
"@
}

$detectionRelativePaths = @(Get-SourceDetectionPaths)

if ($detectionRelativePaths.Count -eq 0) {
    Write-Host 'No source detections require regeneration.'
    exit 0
}

foreach ($detectionRelativePath in $detectionRelativePaths) {
    $sourceDetectionPath = Join-Path $SourceRoot $detectionRelativePath
    $deployDetectionPath = Join-Path $DeployRoot $detectionRelativePath
    $metadataPath = Join-Path $sourceDetectionPath 'metadata.bicep'
    $queryPath = Join-Path $sourceDetectionPath 'query.kql'

    if (-not (Test-Path $sourceDetectionPath)) {
        if (Test-Path $deployDetectionPath) {
            Remove-Item -Path $deployDetectionPath -Recurse -Force
            Write-Host "Removed generated artifacts for deleted detection '$detectionRelativePath'."
        }
        continue
    }

    if (-not (Test-Path $metadataPath) -or -not (Test-Path $queryPath)) {
        throw "Detection '$detectionRelativePath' must contain both metadata.bicep and query.kql."
    }

    $metadataTemplate = az bicep build --file $metadataPath --stdout | Out-String | ConvertFrom-Json
    $metadata = $metadataTemplate.outputs.metadata.value
    $queryText = (Get-Content -Path $queryPath -Raw).TrimEnd("`r", "`n")
    $generatedRuleContent = Get-GeneratedRuleContent -DetectionRelativePath $detectionRelativePath -Metadata $metadata -QueryText $queryText
    $generatedRulePath = Join-Path $deployDetectionPath 'rule.bicep'

    New-Item -Path $deployDetectionPath -ItemType Directory -Force | Out-Null
    Set-Content -Path $generatedRulePath -Value $generatedRuleContent
    Write-Host "Updated generated artifact '$generatedRulePath'."
}