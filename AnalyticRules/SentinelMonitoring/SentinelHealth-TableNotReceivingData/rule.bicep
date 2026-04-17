// Generated file. Do not edit directly.
// Source metadata: src/AnalyticRules/SentinelMonitoring/SentinelHealth-TableNotReceivingData/metadata.bicep
// Source query: src/AnalyticRules/SentinelMonitoring/SentinelHealth-TableNotReceivingData/query.kql

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var ruleName = 'SentinelHealth-TableNotReceivingData'
var ruleDisplayName = 'Sentinel Health - Table Not Receiving Data'
var ruleProperties = json('{"description":"Dynamically checks all billable tables against the SentinelTableThresholds watchlist and alerts when any monitored table has not received data within its configured threshold. Uses the Usage table for automatic discovery -- no hard-coded table list.","enabled":true,"severity":"High","queryFrequency":"PT1H","queryPeriod":"P7D","triggerOperator":"GreaterThan","triggerThreshold":0,"suppressionEnabled":false,"suppressionDuration":"PT1H","tactics":[],"techniques":[],"incidentConfiguration":{"createIncident":true,"groupingConfiguration":{"enabled":true,"reopenClosedIncident":false,"lookbackDuration":"P7D","matchingMethod":"AllEntities","groupByEntities":[],"groupByAlertDetails":[],"groupByCustomDetails":[]}},"eventGroupingSettings":{"aggregationKind":"SingleAlert"},"customDetails":{"alert_time":"LastIngestionTime","alert_table":"TableName"},"entityMappings":[{"entityType":"Account","fieldMappings":[{"identifier":"Name","columnName":"TableName"}]},{"entityType":"Account","fieldMappings":[{"identifier":"FullName","columnName":"alert_minutes_last_event"}]}]}')
var ruleQuery = '''
let TableThresholds = _GetWatchlist('SentinelTableThresholds')
    | where tolower(Maintenance) != "true"
    | project TableName, ThresholdHours = toint(Threshold);
Usage
| where TimeGenerated >= ago(7d)
| summarize LastIngestionTime = max(TimeGenerated) by TableName = DataType
| extend MinutesSinceLastEvent = datetime_diff("minute", now(), LastIngestionTime)
| join kind=inner TableThresholds on TableName
| where MinutesSinceLastEvent >= ThresholdHours * 60
| project TableName, alert_minutes_last_event = MinutesSinceLastEvent, ThresholdHours, LastIngestionTime
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
