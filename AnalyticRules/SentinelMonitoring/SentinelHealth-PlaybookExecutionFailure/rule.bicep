// Generated file. Do not edit directly.
// Source metadata: src/AnalyticRules/SentinelMonitoring/SentinelHealth-PlaybookExecutionFailure/metadata.bicep
// Source query: src/AnalyticRules/SentinelMonitoring/SentinelHealth-PlaybookExecutionFailure/query.kql

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var ruleName = 'SentinelHealth-PlaybookExecutionFailure'
var ruleDisplayName = 'Sentinel Health - Playbook Execution Failure'
var ruleProperties = json('{"description":"Detects playbook (Logic App) execution failures triggered by Sentinel automation rules. Failed playbooks mean automated enrichment or response actions are not executing, leaving incidents without automated triage.","enabled":true,"severity":"Medium","queryFrequency":"PT1H","queryPeriod":"PT1H","triggerOperator":"GreaterThan","triggerThreshold":0,"suppressionEnabled":false,"suppressionDuration":"PT1H","tactics":[],"techniques":[],"incidentConfiguration":{"createIncident":true,"groupingConfiguration":{"enabled":true,"reopenClosedIncident":false,"lookbackDuration":"P1D","matchingMethod":"AllEntities","groupByEntities":[],"groupByAlertDetails":[],"groupByCustomDetails":[]}},"eventGroupingSettings":{"aggregationKind":"SingleAlert"},"customDetails":{"alert_playbook":"PlaybookName","alert_reason":"FailureReason","alert_rule":"TriggeredByRule"},"entityMappings":[{"entityType":"Account","fieldMappings":[{"identifier":"Name","columnName":"PlaybookName"}]}]}')

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
SentinelHealth
| where OperationName == "Playbook was triggered"
| where Status == "Failure"
| extend PlaybookName = tostring(ExtendedProperties.PlaybookName)
| extend TriggeredByRule = tostring(ExtendedProperties.TriggeredByRuleName)
| extend FailureReason = tostring(ExtendedProperties.Reason)
| summarize
    FailureCount = count(),
    FirstFailure = min(TimeGenerated),
    LastFailure = max(TimeGenerated),
    FailureReasons = make_set(FailureReason, 10),
    FailureReason = max(FailureReason),
    TriggeredByRules = make_set(TriggeredByRule, 10),
    TriggeredByRule = max(TriggeredByRule)
    by PlaybookName
| where FailureCount >= 2
'''
  })
}
