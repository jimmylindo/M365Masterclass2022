param networkInterfaceName string
param location string
param privateIPAddress string
param virtualNetworkName string
param subnetName string
param loadbalancer_resource object

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2019-02-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIPAddress
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
              id: '${loadbalancer_resource.id}/inboundNatRules/ACMEDC01-NATRuleRDP'
            }
          ]
        }
      }
    ]
  }
  dependsOn: []
}
