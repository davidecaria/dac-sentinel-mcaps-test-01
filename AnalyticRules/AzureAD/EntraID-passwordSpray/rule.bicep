// Generated file. Do not edit directly.
// Source metadata: src/AnalyticRules/AzureAD/EntraID-passwordSpray/metadata.bicep
// Source query: src/AnalyticRules/AzureAD/EntraID-passwordSpray/query.kql

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var ruleName = 'AAD-PasswordSpray'
var ruleDisplayName = 'AAD Password Spray - Multiple Users Same IP'
var ruleProperties = json('{"description":"Detects multiple failed Azure AD sign-ins from the same IP across multiple users.","enabled":true,"severity":"High","queryFrequency":"PT5M","queryPeriod":"PT5M","triggerOperator":"GreaterThan","triggerThreshold":0,"suppressionEnabled":false,"suppressionDuration":"PT5M","tactics":["CredentialAccess"],"techniques":["T1110"],"entityMappings":[{"entityType":"IP","fieldMappings":[{"identifier":"Address","columnName":"IPAddress"}]}]}')

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
SigninLogs
| where ResultType != 0
| summarize FailedAttempts = count(), Users = dcount(UserPrincipalName) by IPAddress, bin(TimeGenerated, 5m)
| where FailedAttempts >= 10 and Users >= 5
'''
  })
}
