@description('Size of VM')
param vmSize string = 'Standard_B2s'

@description('The name of the administrator of the new VM.')
param adminUsername string

@description('The password for the administrator account of the new VM.')
@secure()
param adminPassword string

@description('Subnet name.')
param subnetName string

@description('Virtual network name.')
param virtualNetworkName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Loadbalancer')
param lbname string

var imagePublisher = 'MicrosoftWindowsDesktop'
var imageOffer = 'windows-11'
var windowsOSVersion = 'win11-21h2-entn'
var ComputerName_var = 'ACME-standalone'
var NetworkInterfaceName_var = 'acme-standalone-Nic'
var PrivateIP_var = '10.0.0.7'

resource loadbalancer_resource 'Microsoft.Network/loadBalancers@2021-05-01' existing = {
  name: lbname
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2019-02-01' = {
  name: NetworkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: PrivateIP_var
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${loadbalancer_resource.id}/backendAddressPools/backendpool-config'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${loadbalancer_resource.id}/inboundNatRules/ACMEStandalone-NATRuleRDP'
            }
          ]
        }
      }
    ]
  }
  dependsOn: []
}

resource ComputerName 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: ComputerName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: ComputerName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 50
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}
