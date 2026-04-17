output metadata object = {
  ruleName: 'SentinelHealth-TableNotReceivingData'
  displayName: 'Sentinel Health - Table Not Receiving Data'
  description: 'Dynamically checks all billable tables against the SentinelTableThresholds watchlist and alerts when any monitored table has not received data within its configured threshold. Uses the Usage table for automatic discovery — no hard-coded table list.'
  enabled: true
  severity: 'High'
  queryFrequency: 'PT1H'
  queryPeriod: 'P7D'
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
      lookbackDuration: 'P7D'
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
    alert_time: 'LastIngestionTime'
    alert_table: 'TableName'
  }
  entityMappings: [
    {
      entityType: 'Account'
      fieldMappings: [
        {
          identifier: 'Name'
          columnName: 'TableName'
        }
      ]
    }
    {
      entityType: 'Account'
      fieldMappings: [
        {
          identifier: 'FullName'
          columnName: 'alert_minutes_last_event'
        }
      ]
    }
  ]
}
