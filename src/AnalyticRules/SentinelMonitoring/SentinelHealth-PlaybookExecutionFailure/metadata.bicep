output metadata object = {
  ruleName: 'SentinelHealth-PlaybookExecutionFailure'
  displayName: 'Sentinel Health - Playbook Execution Failure'
  description: 'Detects playbook (Logic App) execution failures triggered by Sentinel automation rules. Failed playbooks mean automated enrichment or response actions are not executing, leaving incidents without automated triage.'
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
    alert_playbook: 'PlaybookName'
    alert_reason: 'FailureReason'
    alert_rule: 'TriggeredByRule'
  }
  entityMappings: [
    {
      entityType: 'Account'
      fieldMappings: [
        {
          identifier: 'Name'
          columnName: 'PlaybookName'
        }
      ]
    }
  ]
}
