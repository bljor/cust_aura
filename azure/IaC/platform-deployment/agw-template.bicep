param location string
param applicationGatewayName string
param tier string
param skuSize string
param capacity int = 2
param subnetName string
param zones array
param virtualNetworkName string
param virtualNetworkPrefix array
param publicIpZones array
param publicIpAddressName array
param sku array
param allocationMethod array
param ipAddressVersion array
param privateIpAddress array

var vnetId = resourceId('manual-resources', 'Microsoft.Network/virtualNetworks/', virtualNetworkName)
var publicIPRef = [
  publicIpAddressName_0.id
]
var subnetRef = '${vnetId}/subnets/${subnetName}'
var applicationGatewayId = applicationGateway.id

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: applicationGatewayName
  location: location
  zones: zones
  tags: {
    CostCenter: 'Dinel'
    Environment: 'Dev'
    OpsTeam: 'IT-Drift'
  }
  properties: {
    sku: {
      name: skuSize
      tier: tier
      capacity: capacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIpIPv4'
        properties: {
          publicIPAddress: {
            id: publicIPRef[0]
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'manual-agw-backend-001'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'manual-agw-backend-settings-name'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Enabled'
          requestTimeout: 20
          affinityCookieName: 'ApplicationGatewayAffinity'
          connectionDraining: {
            drainTimeoutInSec: 60
            enabled: true
          }
          pickHostNameFromBackendAddress: true
          probe: {
            id: '${applicationGatewayId}/probes/manual-agw-backend-settings-nameea541a63-e7e9-4d4a-95be-aebf588e'
          }
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: 'manual-agw-routing-rule-001-listener001'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
          }
          frontendPort: {
            id: '${applicationGatewayId}/frontendPorts/port_80'
          }
          protocol: 'Http'
          sslCertificate: null
          hostName: 'manual-agw-routing-rule-001-listener001-hostname'
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
    ]
    listeners: []
    requestRoutingRules: [
      {
        name: 'manual-agw-routing-rule-001'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayId}/httpListeners/manual-agw-routing-rule-001-listener001'
          }
          priority: 5000
          backendAddressPool: {
            id: '${applicationGatewayId}/backendAddressPools/manual-agw-backend-001'
          }
          backendHttpSettings: {
            id: '${applicationGatewayId}/backendHttpSettingsCollection/manual-agw-backend-settings-name'
          }
        }
      }
    ]
    routingRules: []
    enableHttp2: false
    sslCertificates: []
    probes: [
      {
        name: 'manual-agw-backend-settings-nameea541a63-e7e9-4d4a-95be-aebf588e'
        properties: {
          backendHttpSettings: [
            {
              id: '${applicationGatewayId}/backendHttpSettingsCollection/manual-agw-backend-settings-name'
            }
          ]
          interval: 30
          minServers: 0
          path: '/'
          protocol: 'Http'
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: virtualNetworkPrefix
    }
    subnets: [
      {
        name: 'manual-subnet001'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'manual-subnet002'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource publicIpAddressName_0 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: publicIpAddressName[0]
  location: location
  sku: {
    name: sku[0]
  }
  zones: publicIpZones
  properties: {
    publicIPAddressVersion: ipAddressVersion[0]
    publicIPAllocationMethod: allocationMethod[0]
  }
}
