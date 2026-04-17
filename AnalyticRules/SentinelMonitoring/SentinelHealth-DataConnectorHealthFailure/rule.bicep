// Generated file. Do not edit directly.
// Source metadata: src/AnalyticRules/SentinelMonitoring/SentinelHealth-DataConnectorHealthFailure/metadata.bicep
// Source query: src/AnalyticRules/SentinelMonitoring/SentinelHealth-DataConnectorHealthFailure/query.kql

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var ruleName = 'SentinelHealth-DataConnectorHealthFailure'
var ruleDisplayName = 'Sentinel Health - Data Connector Health Failure'
var ruleProperties = json('{"description":"Detects data connector health failures reported by the SentinelHealth table. Connector failures are a leading indicator of log source silence ù this rule fires before data gaps form.","enabled":true,"severity":"High","queryFrequency":"PT1H","queryPeriod":"P1D","triggerOperator":"GreaterThan","triggerThreshold":0,"suppressionEnabled":false,"suppressionDuration":"PT1H","tactics":[],"techniques":[],"incidentConfiguration":{"createIncident":true,"groupingConfiguration":{"enabled":true,"reopenClosedIncident":false,"lookbackDuration":"P1D","matchingMethod":"AllEntities","groupByEntities":[],"groupByAlertDetails":[],"groupByCustomDetails":[]}},"eventGroupingSettings":{"aggregationKind":"SingleAlert"},"customDetails":{"alert_connector":"SentinelResourceName","alert_reason":"FailureReason","alert_status":"Status"},"entityMappings":[{"entityType":"Account","fieldMappings":[{"identifier":"Name","columnName":"SentinelResourceName"}]}]}')

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
let LookBack = 1d;
let Frequency = 1h;
SentinelHealth
| where TimeGenerated >= ago(LookBack)
| where OperationName == "Data fetch status change"
| where Status in ("Failure", "Warning")
| extend FailureReason = tostring(ExtendedProperties.Reason)
| summarize
    FirstFailure = min(TimeGenerated),
    LastFailure = max(TimeGenerated),
    FailureCount = count(),
    FailureReasons = make_set(FailureReason, 10),
    FailureReason = max(FailureReason)
    by SentinelResourceName, SentinelResourceKind, Status
| where LastFailure >= ago(Frequency)
| where FailureCount >= 2
'''
  })
}
