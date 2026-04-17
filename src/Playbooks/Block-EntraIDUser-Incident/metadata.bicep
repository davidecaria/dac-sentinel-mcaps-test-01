output metadata object = {
  playbookName: 'Block-EntraIDUser-Incident'
  displayName: 'Block Entra ID User on Incident'
  description: 'Triggers on a Microsoft Sentinel incident and disables the associated user accounts in Entra ID. Notifies the user\'s manager via email and adds comments to the incident.'
  connections: [
    {
      name: 'azuread'
      apiId: 'azuread'
    }
    {
      name: 'microsoftsentinel'
      apiId: 'azuresentinel'
      useManagedIdentity: true
    }
    {
      name: 'office365'
      apiId: 'office365'
    }
  ]
}
