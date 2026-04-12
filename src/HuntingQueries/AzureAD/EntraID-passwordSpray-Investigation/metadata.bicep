output metadata object = {
  queryName: 'Hunt-AADPasswordSprayInvestigation'
  displayName: 'Entra ID Password Spray Investigation'
  category: 'Hunting Queries'
  description: 'Pivot from suspicious Entra ID password spray IPs into affected users, apps, and result codes.'
  version: 2
  tactics: [
    'CredentialAccess'
  ]
  techniques: [
    'T1110'
  ]
  dataSource: 'SigninLogs'
}
