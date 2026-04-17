// Generated file. Do not edit directly.
// Source metadata: src/HuntingQueries/AzureAD/EntraID-passwordSpray-Investigation/metadata.bicep
// Source query: src/HuntingQueries/AzureAD/EntraID-passwordSpray-Investigation/query.kql

targetScope = 'resourceGroup'

param workspace string
param displayNamePrefix string = ''

var queryName = 'Hunt-AADPasswordSprayInvestigation'
var queryDisplayName = 'Entra ID Password Spray Investigation'
var optionalProperties = json('{"tags":[{"name":"description","value":"Pivot from suspicious Entra ID password spray IPs into affected users, apps, and result codes."},{"name":"tactics","value":"CredentialAccess"},{"name":"techniques","value":"T1110"},{"name":"dataSource","value":"SigninLogs"}]}')
var queryText = '''
let lookback = 1d;
let failureWindow = 5m;
let suspiciousIPs =
    SigninLogs
    | where TimeGenerated >= ago(lookback)
    | where ResultType != 0
    | summarize FailedAttempts = count(), TargetedUsers = dcount(UserPrincipalName) by IPAddress, bin(TimeGenerated, failureWindow)
    | where FailedAttempts >= 10 and TargetedUsers >= 5
    | project IPAddress;
SigninLogs
| where TimeGenerated >= ago(lookback)
| where IPAddress in (suspiciousIPs)
| summarize
    FailedAttempts = countif(ResultType != 0),
    SuccessfulAttempts = countif(ResultType == 0),
    TargetedUsers = dcount(UserPrincipalName),
    Users = make_set(UserPrincipalName, 50),
    Apps = make_set(AppDisplayName, 20),
    ResultCodes = make_set(tostring(ResultType), 20),
    LastSeen = max(TimeGenerated)
  by IPAddress
| order by FailedAttempts desc, TargetedUsers desc
'''

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' existing = {
  name: workspace
}

resource huntingQuery 'Microsoft.OperationalInsights/workspaces/savedSearches@2025-02-01' = {
  name: queryName
  parent: logAnalyticsWorkspace
  properties: union(optionalProperties, {
    category: 'Hunting Queries'
    displayName: '${displayNamePrefix}${queryDisplayName}'
    query: queryText
    version: 2
  })
}
