output metadata object = {
  ruleName: 'SentinelHealth-DataConnectorHealthFailure'
  displayName: 'Sentinel Health - Data Connector Health Failure'
  description: 'Detects data connector health failures reported by the SentinelHealth table. Connector failures are a leading indicator of log source silence — this rule fires before data gaps form.'
  enabled: true
  severity: 'High'
  queryFrequency: 'PT1H'
  queryPeriod: 'P1D'
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
    alert_connector: 'SentinelResourceName'
    alert_reason: 'FailureReason'
    alert_status: 'Status'
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
