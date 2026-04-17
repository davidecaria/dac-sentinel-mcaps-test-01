// Generated file. Do not edit directly.
// Source metadata: src/AnalyticRules/SentinelMonitoring/SentinelHealth-FailedAnalyticRules/metadata.bicep
// Source query: src/AnalyticRules/SentinelMonitoring/SentinelHealth-FailedAnalyticRules/query.kql

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var ruleName = 'SentinelHealth-FailedAnalyticRules'
var ruleDisplayName = 'Sentinel Health - Failed Analytic Rule(s)'
var ruleProperties = json('{"description":"Monitors for scheduled analytic rules that have failed execution more than 3 times in the last hour. Persistent failures indicate broken queries or missing data sources that create detection blind spots.","enabled":true,"severity":"Medium","queryFrequency":"PT1H","queryPeriod":"PT1H","triggerOperator":"GreaterThan","triggerThreshold":0,"suppressionEnabled":false,"suppressionDuration":"PT1H","tactics":[],"techniques":[],"incidentConfiguration":{"createIncident":true,"groupingConfiguration":{"enabled":true,"reopenClosedIncident":false,"lookbackDuration":"P1D","matchingMethod":"AllEntities","groupByEntities":[],"groupByAlertDetails":[],"groupByCustomDetails":[]}},"eventGroupingSettings":{"aggregationKind":"SingleAlert"},"customDetails":{"alert_entity":"SentinelResourceName"},"entityMappings":[{"entityType":"Account","fieldMappings":[{"identifier":"Name","columnName":"SentinelResourceName"}]}]}')
var ruleQuery = '''
SentinelHealth
| where OperationName == "Scheduled analytics rule run"
| where Status == "Failure"
| summarize FailureCount = count(), 
    LastFailureTime = max(TimeGenerated),
    FailureReasons = make_set(Description, 5) by SentinelResourceName
| where FailureCount > 3
'''

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspace
}

resource analyticRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  scope: logAnalyticsWorkspace
  name: ruleName
  kind: 'Scheduled'
  properties: union(ruleProperties, {
                displayName: '${displayNamePrefix}${ruleDisplayName}'
    query: ruleQuery
  })
}
