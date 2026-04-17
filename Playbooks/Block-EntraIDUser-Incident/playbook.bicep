// Generated file. Do not edit directly.
// Source metadata: src/Playbooks/Block-EntraIDUser-Incident/metadata.bicep
// Source definition: src/Playbooks/Block-EntraIDUser-Incident/definition.json

targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Name of the Logic App playbook.')
param playbookName string = 'Block-EntraIDUser-Incident'

resource azureadConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'azuread-${playbookName}'
  location: location
  properties: {
    displayName: 'azuread-${playbookName}'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuread')
    }
  }
}

resource microsoftsentinelConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'microsoftsentinel-${playbookName}'
  location: location
  properties: {
    displayName: 'microsoftsentinel-${playbookName}'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuresentinel')
    }
    #disable-next-line BCP037
    parameterValueType: 'Alternative'
  }
}

resource office365Connection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'office365-${playbookName}'
  location: location
  properties: {
    displayName: 'office365-${playbookName}'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
    }
  }
}

resource playbook 'Microsoft.Logic/workflows@2019-05-01' = {
  name: playbookName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: loadJsonContent('./definition.json')
    parameters: {
      '$connections': {
        value: {
          azuread: {
            connectionId: azureadConnection.id
            connectionName: azureadConnection.name
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuread')          }
          microsoftsentinel: {
            connectionId: microsoftsentinelConnection.id
            connectionName: microsoftsentinelConnection.name
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuresentinel')
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }          }
          office365: {
            connectionId: office365Connection.id
            connectionName: office365Connection.name
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')          }
        }
      }
    }
  }
}
