output metadata object = {
  ruleName: 'SentinelHealth-FailedAnalyticRules'
  displayName: 'Sentinel Health - Failed Analytic Rule(s)'
  description: 'Monitors for scheduled analytic rules that have failed execution more than 3 times in the last hour. Persistent failures indicate broken queries or missing data sources that create detection blind spots.'
  enabled: true
  severity: 'Medium'
  queryFrequency: 'PT1H'
  queryPeriod: 'PT1H'
  triggerOperator: 'GreaterThan'
  triggerThreshold: 0
  suppressionEnabled: false
  suppressionDuration: 'PT1H'
  tactics: []
  techniques: []
  incidentConfiguration: {
    createIncident: true
    groupingConfiguration: {
      enabled: true
      reopenClosedIncident: false
      lookbackDuration: 'P1D'
      matchingMethod: 'AllEntities'
      groupByEntities: []
      groupByAlertDetails: []
      groupByCustomDetails: []
    }
  }
  eventGroupingSettings: {
    aggregationKind: 'SingleAlert'
  }
  customDetails: {
    alert_entity: 'SentinelResourceName'
  }
  entityMappings: [
    {
      entityType: 'Account'
      fieldMappings: [
        {
          identifier: 'Name'
          columnName: 'SentinelResourceName'
        }
      ]
    }
  ]
}
