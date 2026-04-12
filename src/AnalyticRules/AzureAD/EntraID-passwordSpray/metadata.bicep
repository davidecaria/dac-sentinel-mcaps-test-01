output metadata object = {
  ruleName: 'AAD-PasswordSpray'
  displayName: 'AAD Password Spray - Multiple Users Same IP v2'
  description: 'Detects multiple failed Azure AD sign-ins from the same IP across multiple users.'
  enabled: true
  severity: 'High'
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
