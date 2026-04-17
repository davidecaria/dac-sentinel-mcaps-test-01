// Generated file. Do not edit directly.
// Source metadata: src/AnalyticRules/SentinelMonitoring/SentinelHealth-LogIngestionSpikeOrDrop/metadata.bicep
// Source query: src/AnalyticRules/SentinelMonitoring/SentinelHealth-LogIngestionSpikeOrDrop/query.kql

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var ruleName = 'SentinelHealth-LogIngestionSpikeOrDrop'
var ruleDisplayName = 'Sentinel Health - Log Ingestion Spike or Drop'
var ruleProperties = json('{"description":"Monitors for significant spikes or drops in daily billable log ingestion volume compared to a 14-day weekday average. A deviation of more than 30% triggers an alert to avoid unexpected costs or silent data loss.","enabled":true,"severity":"Low","queryFrequency":"P1D","queryPeriod":"P14D","triggerOperator":"GreaterThan","triggerThreshold":0,"suppressionEnabled":false,"suppressionDuration":"PT1H","tactics":[],"techniques":[],"incidentConfiguration":{"createIncident":true,"groupingConfiguration":{"enabled":true,"reopenClosedIncident":false,"lookbackDuration":"P1D","matchingMethod":"AllEntities","groupByEntities":[],"groupByAlertDetails":[],"groupByCustomDetails":[]}},"eventGroupingSettings":{"aggregationKind":"SingleAlert"},"customDetails":{"alert_time":"TimeGenerated"},"entityMappings":[{"entityType":"Account","fieldMappings":[{"identifier":"Name","columnName":"DailyVolumeGB"}]}]}')

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
let searchdays = 14;
let lookbackdays = 2;
let DailyVolumeData =
    Usage
    | where TimeGenerated > startofday(ago(searchdays * 1d)) and TimeGenerated < startofday(now())
    | where IsBillable == true
    | summarize DailyVolumeGB = sum(Quantity) / 1000 by bin(TimeGenerated, 1d)
    | where dayofweek(TimeGenerated) !in (0d, 6d);
DailyVolumeData
| extend AverageVolumeGB = toscalar(DailyVolumeData
    | summarize avg(DailyVolumeGB))
| extend Alert = case(
    DailyVolumeGB > AverageVolumeGB * 1.3, "Spike",
    DailyVolumeGB < AverageVolumeGB * 0.7, "Drop",
    "Normal")
| where TimeGenerated > startofday(ago(lookbackdays * 1d))
| where Alert == "Spike" or Alert == "Drop"
| project TimeGenerated, DailyVolumeGB, AverageVolumeGB, Alert
'''
  })
}
