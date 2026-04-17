output metadata object = {
  ruleName: 'SentinelHealth-LogIngestionSpikeOrDrop'
  displayName: 'Sentinel Health - Log Ingestion Spike or Drop'
  description: 'Monitors for significant spikes or drops in daily billable log ingestion volume compared to a 14-day weekday average. A deviation of more than 30% triggers an alert to avoid unexpected costs or silent data loss.'
  enabled: true
  severity: 'Low'
  queryFrequency: 'P1D'
  queryPeriod: 'P14D'
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
    alert_time: 'TimeGenerated'
  }
  entityMappings: [
    {
      entityType: 'Account'
      fieldMappings: [
        {
          identifier: 'Name'
          columnName: 'DailyVolumeGB'
        }
      ]
    }
  ]
}
