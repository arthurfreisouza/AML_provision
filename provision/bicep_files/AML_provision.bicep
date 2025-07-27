@description('The base name for all resources. A unique string will be appended to this name.')
@minLength(3)
@maxLength(11) // Corrected: Changed from 12 to 11 to meet the 24-char limit for the storage account name.
param baseName string = 'mlops'

@description('The Azure region where the resources should be deployed.')
param location string = resourceGroup().location

@description('The SKU for the Machine Learning workspace.')
param sku string = 'Basic'

// Generate unique names for resources to avoid naming conflicts
var storageAccountName = '${baseName}${uniqueString(resourceGroup().id)}'
var keyVaultName = '${baseName}kv${uniqueString(resourceGroup().id)}'
var appInsightsName = '${baseName}ai${uniqueString(resourceGroup().id)}'
var containerRegistryName = '${baseName}acr${uniqueString(resourceGroup().id)}'
var workspaceName = '${baseName}mlw${uniqueString(resourceGroup().id)}'

// Resource: Azure Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
  }
}

// Resource: Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}

// Resource: Azure Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// Resource: Azure Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Resource: Azure Machine Learning Workspace
resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: workspaceName
  location: location
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: workspaceName
    description: 'Azure ML Workspace deployed via Bicep'
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: appInsights.id
    containerRegistry: containerRegistry.id
    hbiWorkspace: false
  }
  // Corrected: Removed the unnecessary 'dependsOn' block.
  // Bicep infers these dependencies automatically from the property assignments above.
}

// Outputs
output mlWorkspaceName string = mlWorkspace.name
output mlWorkspaceStudioUrl string = mlWorkspace.properties.discoveryUrl // Corrected: Changed property from 'workspaceUrl' to 'discoveryUrl'
