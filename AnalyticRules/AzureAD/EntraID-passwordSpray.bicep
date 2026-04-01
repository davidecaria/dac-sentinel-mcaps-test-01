targetScope = 'resourceGroup'

param workspace string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspace
}

resource passwordSprayRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  scope: logAnalyticsWorkspace
  name: 'AAD-PasswordSpray'
  kind: 'Scheduled'
  properties: {
    displayName: 'AAD Password Spray - Multiple Users Same IP'
    description: 'Detects multiple failed Azure AD sign-ins from the same IP across multiple users.'
    enabled: true
    severity: 'High'
    query: loadTextContent('EntraID-passwordSpray.kql')
    queryFrequency: 'PT5M'
    queryPeriod: 'PT5M'
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
    suppressionEnabled: false
    suppressionDuration: 'PT5M'
    tactics: [
      'CredentialAccess'
    ]
    techniques: [
      'T1110'
    ]
    entityMappings: [
      {
        entityType: 'IP'
        fieldMappings: [
          {
            identifier: 'Address'
            columnName: 'IPAddress'
          }
        ]
      }
    ]
  }
}
