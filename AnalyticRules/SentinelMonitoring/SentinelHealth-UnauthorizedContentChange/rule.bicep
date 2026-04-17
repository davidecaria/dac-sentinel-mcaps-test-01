// Generated file. Do not edit directly.
// Source metadata: src/AnalyticRules/SentinelMonitoring/SentinelHealth-UnauthorizedContentChange/metadata.bicep
// Source query: src/AnalyticRules/SentinelMonitoring/SentinelHealth-UnauthorizedContentChange/query.kql

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var ruleName = 'SentinelHealth-UnauthorizedContentChange'
var ruleDisplayName = 'Sentinel Health - Unauthorized Sentinel Content Change'
var ruleProperties = json('{"description":"Sentinel content was modified by an identity not listed in the SentinelAuthorizedCallers watchlist. This detects manual portal edits, unauthorized API changes, or rogue automation modifying analytic rules, connectors, or other Sentinel resources.","enabled":true,"severity":"Low","queryFrequency":"PT1H","queryPeriod":"PT1H","triggerOperator":"GreaterThan","triggerThreshold":0,"suppressionEnabled":false,"suppressionDuration":"PT1H","tactics":[],"techniques":[],"incidentConfiguration":{"createIncident":true,"groupingConfiguration":{"enabled":true,"reopenClosedIncident":false,"lookbackDuration":"P1D","matchingMethod":"AllEntities","groupByEntities":[],"groupByAlertDetails":[],"groupByCustomDetails":[]}},"eventGroupingSettings":{"aggregationKind":"SingleAlert"},"customDetails":{"alert_user":"CallerName_","alert_entity":"SentinelResourceName"},"entityMappings":[{"entityType":"Account","fieldMappings":[{"identifier":"Name","columnName":"SentinelResourceName"}]},{"entityType":"Account","fieldMappings":[{"identifier":"Name","columnName":"CallerName_"}]}]}')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspace
}

resource analyticRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  scope: logAnalyticsWorkspace
  name: ruleName
  kind: 'Scheduled'
  properties: union(ruleProperties, {
                displayName: '${displayNamePrefix}${ruleDisplayName}'
    query: '''
let AuthorizedCallers = _GetWatchlist('SentinelAuthorizedCallers')
    | project PrincipalId;
SentinelAudit
| extend CallerName_ = tostring(ExtendedProperties.CallerName)
| where CallerName_ !in (AuthorizedCallers)
| where isnotempty(SentinelResourceName)
'''
  })
}
