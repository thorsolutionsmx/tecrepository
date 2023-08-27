targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'ms.documentdb.databaseaccounts-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'dddasql'

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

@description('Optional. A token to inject into the name of each resource.')
param namePrefix string = '[[namePrefix]]'

// ============ //
// Dependencies //
// ============ //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

module nestedDependencies 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-nestedDependencies'
  params: {
    managedIdentityName: 'dep-${namePrefix}-msi-${serviceShort}'
    virtualNetworkName: 'dep-${namePrefix}-vnet-${serviceShort}'
  }
}

// Diagnostics
// ===========
module diagnosticDependencies '../../../../.shared/.templates/diagnostic.dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-diagnosticDependencies'
  params: {
    storageAccountName: 'dep${namePrefix}diasa${serviceShort}01'
    logAnalyticsWorkspaceName: 'dep-${namePrefix}-law-${serviceShort}'
    eventHubNamespaceEventHubName: 'dep-${namePrefix}-evh-${serviceShort}'
    eventHubNamespaceName: 'dep-${namePrefix}-evhns-${serviceShort}'
    location: location
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}'
  params: {
    enableDefaultTelemetry: enableDefaultTelemetry
    name: '${namePrefix}${serviceShort}001'
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: 'West Europe'
      }
      {
        failoverPriority: 1
        isZoneRedundant: false
        locationName: 'North Europe'
      }
    ]
    diagnosticStorageAccountId: diagnosticDependencies.outputs.storageAccountResourceId
    diagnosticWorkspaceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
    diagnosticEventHubAuthorizationRuleId: diagnosticDependencies.outputs.eventHubAuthorizationRuleId
    diagnosticEventHubName: diagnosticDependencies.outputs.eventHubNamespaceEventHubName
    diagnosticLogsRetentionInDays: 7
    location: location
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDNSResourceIds: [
            nestedDependencies.outputs.privateDNSResourceId
          ]
        }
        service: 'Sql'
        subnetResourceId: nestedDependencies.outputs.subnetResourceId
        tags: {
          Environment: 'Non-Prod'
          Role: 'DeploymentValidation'
        }
      }
    ]
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          nestedDependencies.outputs.managedIdentityPrincipalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
    sqlDatabases: [
      {
        containers: [
          {
            kind: 'Hash'
            name: 'container-001'
            indexingPolicy: {
              automatic: true
            }
            paths: [
              '/myPartitionKey'
            ]
            analyticalStorageTtl: 0
            conflictResolutionPolicy: {
              conflictResolutionPath: '/myCustomId'
              mode: 'LastWriterWins'
            }
            defaultTtl: 1000
            uniqueKeyPolicyKeys: [
              {
                paths: [
                  '/firstName'
                ]
              }
              {
                paths: [
                  '/lastName'
                ]
              }
            ]
            throughput: 600
          }
        ]
        name: '${namePrefix}-sql-${serviceShort}-001'
        throughput: 1000
      }
      {
        containers: []
        name: '${namePrefix}-sql-${serviceShort}-002'
      }
      {
        containers: [
          {
            kind: 'Hash'
            name: 'container-003'
            autoscaleSettingsMaxThroughput: 1000
            indexingPolicy: {
              automatic: true
            }
            paths: [
              '/myPartitionKey'
            ]
            analyticalStorageTtl: 0
            conflictResolutionPolicy: {
              conflictResolutionPath: '/myCustomId'
              mode: 'LastWriterWins'
            }
            defaultTtl: 1000
            uniqueKeyPolicyKeys: [
              {
                paths: [
                  '/firstName'
                ]
              }
              {
                paths: [
                  '/lastName'
                ]
              }
            ]
          }
        ]
        name: '${namePrefix}-sql-${serviceShort}-003'
        autoscaleSettingsMaxThroughput: 1000
      }
    ]
    userAssignedIdentities: {
      '${nestedDependencies.outputs.managedIdentityResourceId}': {}
    }
    tags: {
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
}
