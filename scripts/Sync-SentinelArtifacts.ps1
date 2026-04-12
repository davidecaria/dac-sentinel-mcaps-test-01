param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$SourceRoot,
    [string]$DeployRoot,
    [string]$HuntingSourceRoot,
    [string]$HuntingDeployRoot,
    [string]$AdsCatalogPath,
    [string]$ContentCatalogPath,
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

if (-not $HuntingSourceRoot) {
    $HuntingSourceRoot = Join-Path $RepositoryRoot 'src\HuntingQueries'
}

if (-not $HuntingDeployRoot) {
    $HuntingDeployRoot = Join-Path $RepositoryRoot 'HuntingQueries'
}

if (-not $AdsCatalogPath) {
    $AdsCatalogPath = Join-Path $RepositoryRoot 'docs\ADS-Catalog.md'
}

if (-not $ContentCatalogPath) {
    $ContentCatalogPath = Join-Path $RepositoryRoot 'docs\Content-Catalog.md'
}

$SupportedDeployRoots = [ordered]@{
    'AnalyticRules'    = 'AnalyticsRule'
    'AutomationRules'  = 'AutomationRule'
    'HuntingQueries'   = 'HuntingQuery'
    'Parsers'          = 'Parser'
    'Playbooks'        = 'Playbook'
    'Workbooks'        = 'Workbook'
    'CustomDetections' = 'CustomDetection'
}

$GeneratedSourceRoots = [ordered]@{
    'AnalyticRules'  = 'src/AnalyticRules'
    'HuntingQueries' = 'src/HuntingQueries'
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

function Get-SourceContentPaths {
    param([string]$SourceContentRoot)

    if (-not (Test-Path $SourceContentRoot)) {
        return @()
    }

    if ($RebuildAll -or [string]::IsNullOrWhiteSpace($BaseCommit) -or $BaseCommit -eq '0000000000000000000000000000000000000000') {
        return Get-ChildItem -Path $SourceContentRoot -Recurse -Filter metadata.bicep |
            ForEach-Object { Get-NormalizedRelativePath -BasePath $SourceContentRoot -TargetPath $_.DirectoryName } |
            Sort-Object -Unique
    }

    $sourceRootRelativePath = Get-NormalizedRelativePath -BasePath $RepositoryRoot -TargetPath $SourceContentRoot
    $changedFiles = git diff --name-only $BaseCommit $HeadCommit -- $sourceRootRelativePath

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

            Get-NormalizedRelativePath -BasePath $SourceContentRoot -TargetPath $absoluteDirectory
        } |
        Where-Object { $_ -and $_ -ne '.' } |
        Sort-Object -Unique
}

function Get-AllSourceContentPaths {
    param([string]$SourceContentRoot)

    if (-not (Test-Path $SourceContentRoot)) {
        return @()
    }

    return Get-ChildItem -Path $SourceContentRoot -Recurse -Filter metadata.bicep |
        ForEach-Object { Get-NormalizedRelativePath -BasePath $SourceContentRoot -TargetPath $_.DirectoryName } |
        Sort-Object -Unique
}

function Get-AdsFrontMatter {
    param([string]$AdsPath)

    if (-not (Test-Path $AdsPath)) {
        throw "Detection ADS file not found: $AdsPath"
    }

    $lines = Get-Content -Path $AdsPath
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') {
        throw "ADS file '$AdsPath' must start with a front matter block delimited by --- lines."
    }

    $frontMatter = [ordered]@{}
    $closingDelimiterFound = $false

    for ($index = 1; $index -lt $lines.Count; $index++) {
        $line = $lines[$index].Trim()

        if ($line -eq '---') {
            $closingDelimiterFound = $true
            break
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line -match '^(?<key>[A-Za-z0-9_-]+)\s*:\s*(?<value>.*)$') {
            $frontMatter[$matches.key] = $matches.value.Trim()
            continue
        }

        throw "ADS front matter line '$line' in '$AdsPath' is not in 'key: value' format."
    }

    if (-not $closingDelimiterFound) {
        throw "ADS file '$AdsPath' is missing the closing front matter delimiter."
    }

    return [pscustomobject]$frontMatter
}

function ConvertTo-MarkdownCell {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ''
    }

    $text = if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        (@($Value) | ForEach-Object { [string]$_ }) -join ', '
    }
    else {
        [string]$Value
    }

    return $text.Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ')
}

function Get-FrontMatterValue {
    param(
        [pscustomobject]$FrontMatter,
        [string]$Key,
        [string]$DefaultValue = ''
    )

    if ($FrontMatter.PSObject.Properties.Name -contains $Key) {
        return [string]$FrontMatter.$Key
    }

    return $DefaultValue
}

function Get-MarkdownPathLink {
    param(
        [string]$CatalogDirectory,
        [string]$TargetPath
    )

    $displayPath = Get-NormalizedRelativePath -BasePath $RepositoryRoot -TargetPath $TargetPath
    $relativeTarget = Get-NormalizedRelativePath -BasePath $CatalogDirectory -TargetPath $TargetPath
    $encodedTarget = $relativeTarget.Replace(' ', '%20')

    return "[$displayPath]($encodedTarget)"
}

function Get-AuthoringModelDescription {
    param([string]$DeployRootName)

    if ($GeneratedSourceRoots.Keys -contains $DeployRootName) {
        return "Generated from $($GeneratedSourceRoots[$DeployRootName])/**"
    }

    return 'Deploy root reserved; onboard a source model under src/** before authoring templates here.'
}

function Add-GeneratedTag {
    param(
        [System.Collections.Generic.List[object]]$TagList,
        [string]$Name,
        [AllowNull()][object]$Value
    )

    if ($null -eq $Value) {
        return
    }

    $tagValue = if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        (@($Value) |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ', '
    }
    else {
        [string]$Value
    }

    if ([string]::IsNullOrWhiteSpace($tagValue)) {
        return
    }

    $TagList.Add([ordered]@{
        name = $Name
        value = $tagValue
    })
}

function Get-DeployableTemplateEntries {
    $entries = New-Object System.Collections.Generic.List[object]

    foreach ($deployRootName in $SupportedDeployRoots.Keys) {
        $deployRootPath = Join-Path $RepositoryRoot $deployRootName
        if (-not (Test-Path $deployRootPath)) {
            continue
        }

        $templates = Get-ChildItem -Path $deployRootPath -Recurse -Include *.bicep, *.json -File |
            Where-Object {
                $_.Name -ne 'bicepconfig.json' -and
                $_.Name -notlike '*metadata.json' -and
                $_.Name -notlike '*.parameters*.json' -and
                $_.Name -notlike '*.bicepparam'
            } |
            Sort-Object FullName

        foreach ($template in $templates) {
            $entries.Add([pscustomobject]@{
                DeployRoot   = $deployRootName
                ContentType  = $SupportedDeployRoots[$deployRootName]
                TemplatePath = $template.FullName
            })
        }
    }

    return $entries
}

function Get-TemplateParameterLinks {
    param(
        [string]$CatalogDirectory,
        [string]$TemplatePath
    )

    $templateDirectory = Split-Path -Parent $TemplatePath
    $templateBaseName = [System.IO.Path]::GetFileNameWithoutExtension($TemplatePath)
    $escapedTemplateBaseName = [regex]::Escape($templateBaseName)

    $parameterFiles = Get-ChildItem -Path $templateDirectory -File |
        Where-Object {
            $_.Name -match "^$escapedTemplateBaseName(\.parameters(-[^.]+)?\.json|(-[^.]+)?\.bicepparam)$"
        } |
        Sort-Object Name

    return @(
        $parameterFiles | ForEach-Object {
            Get-MarkdownPathLink -CatalogDirectory $CatalogDirectory -TargetPath $_.FullName
        }
    )
}

function Get-ContentCatalogContent {
    $catalogDirectory = Split-Path -Parent $ContentCatalogPath
    $header = @(
        '# Sentinel Content Catalog',
        '',
        'Generated file. Do not edit directly.',
        '',
        '## Supported Repository Roots',
        '',
        '| Deploy Root | Sentinel Content Type | Authoring Model |',
        '| --- | --- | --- |'
    )

    $supportedRows = foreach ($deployRootName in $SupportedDeployRoots.Keys) {
        $authoringModel = Get-AuthoringModelDescription -DeployRootName $deployRootName

        "| $(ConvertTo-MarkdownCell $deployRootName) | $(ConvertTo-MarkdownCell $SupportedDeployRoots[$deployRootName]) | $(ConvertTo-MarkdownCell $authoringModel) |"
    }

    $contentEntries = @(Get-DeployableTemplateEntries)
    $contentHeader = @(
        '',
        '## Current Deployable Content',
        '',
        '| Content Type | Origin | Template | Parameter Files |',
        '| --- | --- | --- | --- |'
    )

    if ($contentEntries.Count -eq 0) {
        return ($header + $supportedRows + $contentHeader + '| n/a | n/a | n/a | n/a |') -join "`n"
    }

    $rows = foreach ($contentEntry in $contentEntries) {
        $origin = Get-AuthoringModelDescription -DeployRootName $contentEntry.DeployRoot

        $templateLink = Get-MarkdownPathLink -CatalogDirectory $catalogDirectory -TargetPath $contentEntry.TemplatePath
        $parameterLinks = @(Get-TemplateParameterLinks -CatalogDirectory $catalogDirectory -TemplatePath $contentEntry.TemplatePath)
        $parameterCell = if ($parameterLinks.Count -gt 0) {
            $parameterLinks -join '<br>'
        }
        else {
            ''
        }

        "| $(ConvertTo-MarkdownCell $contentEntry.ContentType) | $(ConvertTo-MarkdownCell $origin) | $templateLink | $(ConvertTo-MarkdownCell $parameterCell) |"
    }

    return ($header + $supportedRows + $contentHeader + $rows) -join "`n"
}

function Get-AdsCatalogContent {
    param([string[]]$DetectionRelativePaths)

    $catalogDirectory = Split-Path -Parent $AdsCatalogPath
    $header = @(
        '# ADS Catalog',
        '',
        'Generated file. Do not edit directly.',
        '',
        '| Detection | Status | Priority | Severity | Owner | Rule Name | Tactics | Query | Metadata | Rule | ADS |',
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |'
    )

    if ($DetectionRelativePaths.Count -eq 0) {
        return ($header + '', 'No detections found.') -join "`n"
    }

    $rows = foreach ($detectionRelativePath in $DetectionRelativePaths) {
        $sourceDetectionPath = Join-Path $SourceRoot $detectionRelativePath
        $metadataPath = Join-Path $sourceDetectionPath 'metadata.bicep'
        $queryPath = Join-Path $sourceDetectionPath 'query.kql'
        $adsPath = Join-Path $sourceDetectionPath 'ads.md'
        $generatedRulePath = Join-Path (Join-Path $DeployRoot $detectionRelativePath) 'rule.bicep'
        $metadataTemplate = az bicep build --file $metadataPath --stdout | Out-String | ConvertFrom-Json
        $metadata = $metadataTemplate.outputs.metadata.value
        $frontMatter = Get-AdsFrontMatter -AdsPath $adsPath
        $status = Get-FrontMatterValue -FrontMatter $frontMatter -Key 'status' -DefaultValue 'unspecified'
        $priority = Get-FrontMatterValue -FrontMatter $frontMatter -Key 'priority' -DefaultValue 'unspecified'
        $owner = Get-FrontMatterValue -FrontMatter $frontMatter -Key 'owner' -DefaultValue 'unassigned'
        $tactics = if ($metadata.PSObject.Properties.Name -contains 'tactics') { $metadata.tactics } else { @() }
        $queryLink = Get-MarkdownPathLink -CatalogDirectory $catalogDirectory -TargetPath $queryPath
        $metadataLink = Get-MarkdownPathLink -CatalogDirectory $catalogDirectory -TargetPath $metadataPath
        $generatedRuleLink = Get-MarkdownPathLink -CatalogDirectory $catalogDirectory -TargetPath $generatedRulePath
        $adsLink = Get-MarkdownPathLink -CatalogDirectory $catalogDirectory -TargetPath $adsPath

        "| $(ConvertTo-MarkdownCell $metadata.displayName) | $(ConvertTo-MarkdownCell $status) | $(ConvertTo-MarkdownCell $priority) | $(ConvertTo-MarkdownCell $metadata.severity) | $(ConvertTo-MarkdownCell $owner) | $(ConvertTo-MarkdownCell $metadata.ruleName) | $(ConvertTo-MarkdownCell $tactics) | $queryLink | $metadataLink | $generatedRuleLink | $adsLink |"
    }

    return ($header + $rows) -join "`n"
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

function Get-GeneratedHuntingQueryContent {
    param(
        [string]$HuntingQueryRelativePath,
        [pscustomobject]$Metadata,
        [string]$QueryText
    )

    $supportedMetadataProperties = @(
        'queryName',
        'displayName',
        'category',
        'version',
        'description',
        'tactics',
        'techniques',
        'dataSource',
        'functionAlias',
        'functionParameters',
        'tags',
        'etag'
    )

    foreach ($property in $Metadata.PSObject.Properties) {
        if ($supportedMetadataProperties -notcontains $property.Name) {
            throw "Source metadata for '$HuntingQueryRelativePath' contains unsupported property '$($property.Name)'."
        }
    }

    foreach ($requiredProperty in @('queryName', 'displayName')) {
        if (-not ($Metadata.PSObject.Properties.Name -contains $requiredProperty)) {
            throw "Source metadata for '$HuntingQueryRelativePath' is missing required property '$requiredProperty'."
        }
    }

    $tags = New-Object System.Collections.Generic.List[object]
    Add-GeneratedTag -TagList $tags -Name 'description' -Value $(if ($Metadata.PSObject.Properties.Name -contains 'description') { $Metadata.description } else { $null })
    Add-GeneratedTag -TagList $tags -Name 'tactics' -Value $(if ($Metadata.PSObject.Properties.Name -contains 'tactics') { $Metadata.tactics } else { $null })
    Add-GeneratedTag -TagList $tags -Name 'techniques' -Value $(if ($Metadata.PSObject.Properties.Name -contains 'techniques') { $Metadata.techniques } else { $null })
    Add-GeneratedTag -TagList $tags -Name 'dataSource' -Value $(if ($Metadata.PSObject.Properties.Name -contains 'dataSource') { $Metadata.dataSource } else { $null })

    if ($Metadata.PSObject.Properties.Name -contains 'tags') {
        foreach ($tag in @($Metadata.tags)) {
            if (-not ($tag.PSObject.Properties.Name -contains 'name') -or -not ($tag.PSObject.Properties.Name -contains 'value')) {
                throw "Source metadata for '$HuntingQueryRelativePath' contains a tag without both 'name' and 'value'."
            }

            Add-GeneratedTag -TagList $tags -Name ([string]$tag.name) -Value ([string]$tag.value)
        }
    }

    $escapedQueryName = Escape-BicepString $Metadata.queryName
    $escapedDisplayName = Escape-BicepString $Metadata.displayName
    $escapedCategory = Escape-BicepString $(if ($Metadata.PSObject.Properties.Name -contains 'category' -and -not [string]::IsNullOrWhiteSpace([string]$Metadata.category)) { [string]$Metadata.category } else { 'Hunting Queries' })
    $escapedEtag = Escape-BicepString $(if ($Metadata.PSObject.Properties.Name -contains 'etag' -and -not [string]::IsNullOrWhiteSpace([string]$Metadata.etag)) { [string]$Metadata.etag } else { '*' })
    $queryVersion = if ($Metadata.PSObject.Properties.Name -contains 'version') { [int]$Metadata.version } else { 2 }
    $inlineQuery = ConvertTo-BicepMultilineString -Value $QueryText
    $sourceMetadataPath = Get-NormalizedRelativePath -BasePath $RepositoryRoot -TargetPath (Join-Path $HuntingSourceRoot (Join-Path $HuntingQueryRelativePath 'metadata.bicep'))
    $sourceQueryPath = Get-NormalizedRelativePath -BasePath $RepositoryRoot -TargetPath (Join-Path $HuntingSourceRoot (Join-Path $HuntingQueryRelativePath 'query.kql'))

    $optionalProperties = [ordered]@{}
    foreach ($optionalPropertyName in @('functionAlias', 'functionParameters')) {
        if ($Metadata.PSObject.Properties.Name -contains $optionalPropertyName) {
            $optionalProperties[$optionalPropertyName] = [string]$Metadata.$optionalPropertyName
        }
    }

    if ($tags.Count -gt 0) {
        $optionalProperties['tags'] = $tags.ToArray()
    }

    $optionalPropertiesJson = ConvertTo-Json -InputObject $optionalProperties -Depth 100 -Compress
    $escapedOptionalPropertiesJson = Escape-BicepString $optionalPropertiesJson

    return @"
// Generated file. Do not edit directly.
// Source metadata: $sourceMetadataPath
// Source query: $sourceQueryPath

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var queryName = '$escapedQueryName'
var queryDisplayName = '$escapedDisplayName'
var optionalProperties = json('$escapedOptionalPropertiesJson')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' existing = {
  name: workspace
}

resource huntingQuery 'Microsoft.OperationalInsights/workspaces/savedSearches@2025-02-01' = {
  name: queryName
  parent: logAnalyticsWorkspace
  etag: '$escapedEtag'
  properties: union(optionalProperties, {
    category: '$escapedCategory'
    displayName: '`${displayNamePrefix}`${queryDisplayName}'
    query: $inlineQuery
    version: $queryVersion
  })
}
"@
}

$detectionRelativePaths = @(Get-SourceContentPaths -SourceContentRoot $SourceRoot)

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

if ($detectionRelativePaths.Count -eq 0) {
    Write-Host 'No source detections required artifact regeneration.'
}

$huntingQueryRelativePaths = @(Get-SourceContentPaths -SourceContentRoot $HuntingSourceRoot)

foreach ($huntingQueryRelativePath in $huntingQueryRelativePaths) {
    $sourceHuntingQueryPath = Join-Path $HuntingSourceRoot $huntingQueryRelativePath
    $deployHuntingQueryPath = Join-Path $HuntingDeployRoot $huntingQueryRelativePath
    $metadataPath = Join-Path $sourceHuntingQueryPath 'metadata.bicep'
    $queryPath = Join-Path $sourceHuntingQueryPath 'query.kql'

    if (-not (Test-Path $sourceHuntingQueryPath)) {
        if (Test-Path $deployHuntingQueryPath) {
            Remove-Item -Path $deployHuntingQueryPath -Recurse -Force
            Write-Host "Removed generated artifacts for deleted hunting query '$huntingQueryRelativePath'."
        }
        continue
    }

    if (-not (Test-Path $metadataPath) -or -not (Test-Path $queryPath)) {
        throw "Hunting query '$huntingQueryRelativePath' must contain both metadata.bicep and query.kql."
    }

    $metadataTemplate = az bicep build --file $metadataPath --stdout | Out-String | ConvertFrom-Json
    $metadata = $metadataTemplate.outputs.metadata.value
    $queryText = (Get-Content -Path $queryPath -Raw).TrimEnd("`r", "`n")
    $generatedQueryContent = Get-GeneratedHuntingQueryContent -HuntingQueryRelativePath $huntingQueryRelativePath -Metadata $metadata -QueryText $queryText
    $generatedQueryPath = Join-Path $deployHuntingQueryPath 'query.bicep'

    New-Item -Path $deployHuntingQueryPath -ItemType Directory -Force | Out-Null
    Set-Content -Path $generatedQueryPath -Value $generatedQueryContent
    Write-Host "Updated generated artifact '$generatedQueryPath'."
}

if ($huntingQueryRelativePaths.Count -eq 0) {
    Write-Host 'No source hunting queries required artifact regeneration.'
}

$allDetectionRelativePaths = @(Get-AllSourceContentPaths -SourceContentRoot $SourceRoot)
$adsCatalogContent = Get-AdsCatalogContent -DetectionRelativePaths $allDetectionRelativePaths
$adsCatalogDirectory = Split-Path -Parent $AdsCatalogPath

if (-not [string]::IsNullOrWhiteSpace($adsCatalogDirectory)) {
    New-Item -Path $adsCatalogDirectory -ItemType Directory -Force | Out-Null
}

Set-Content -Path $AdsCatalogPath -Value $adsCatalogContent
Write-Host "Updated ADS catalog '$AdsCatalogPath'."

$contentCatalogContent = Get-ContentCatalogContent
$contentCatalogDirectory = Split-Path -Parent $ContentCatalogPath

if (-not [string]::IsNullOrWhiteSpace($contentCatalogDirectory)) {
    New-Item -Path $contentCatalogDirectory -ItemType Directory -Force | Out-Null
}

Set-Content -Path $ContentCatalogPath -Value $contentCatalogContent
Write-Host "Updated content catalog '$ContentCatalogPath'."