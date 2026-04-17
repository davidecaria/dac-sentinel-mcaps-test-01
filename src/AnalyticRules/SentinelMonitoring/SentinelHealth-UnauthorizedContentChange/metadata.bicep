output metadata object = {
  ruleName: 'SentinelHealth-UnauthorizedContentChange'
  displayName: 'Sentinel Health - Unauthorized Sentinel Content Change'
  description: 'Sentinel content was modified by an identity not listed in the SentinelAuthorizedCallers watchlist. This detects manual portal edits, unauthorized API changes, or rogue automation modifying analytic rules, connectors, or other Sentinel resources.'
  enabled: true
  severity: 'Low'
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
    alert_user: 'CallerName_'
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
    {
      entityType: 'Account'
      fieldMappings: [
        {
          identifier: 'Name'
          columnName: 'CallerName_'
        }
      ]
    }
  ]
}
