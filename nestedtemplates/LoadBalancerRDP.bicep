param lbname string
param location string
param AzureVM_LB_PIP string
param Frontend string
param Backend string


var sku = 'Standard'
var tier = 'Regional'



resource loadbalancer_resource 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: lbname
  location: location
  tags: {}
  properties: {
    frontendIPConfigurations: [
      {
        name: Frontend
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', AzureVM_LB_PIP) 
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: Backend
      }
    ]
    probes: []
    loadBalancingRules: []
    inboundNatRules: [
    
    ]
    outboundRules: []
  }
  sku: {
    name: sku
    tier: tier
  }
  dependsOn: []
}
