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
      {
        name: 'ACMEDC01-NATRuleRDP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', lbname, 'Frontend-config')
          }
          backendPort: 3389
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'TCP'
          enableTcpReset: false
          frontendPort: 50001
        }
      }
      {
        name: 'ACMECL01-NATRuleRDP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', lbname, 'Frontend-config')
          }
          backendPort: 3389
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'TCP'
          enableTcpReset: false
          frontendPort: 50002
        }
      }
      {
        name: 'ACMEME01-NATRuleRDP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', lbname, 'Frontend-config')
          }
          backendPort: 3389
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'TCP'
          enableTcpReset: false
          frontendPort: 50003
        }
      }
      {
        name: 'ACMEStandalone-NATRuleRDP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', lbname, 'Frontend-config')
          }
          backendPort: 3389
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'TCP'
          enableTcpReset: false
          frontendPort: 50004
        }
      }
    ]
    outboundRules: [
      {
        name: 'Internet-Access'
        properties: {
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', lbname, 'Frontend-config')
            }
          ]
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbname, 'backendpool-config')
          }
          protocol: 'All'
          enableTcpReset: true
          idleTimeoutInMinutes: 4
          allocatedOutboundPorts: 0
        }
      }
    ]
  }
  sku: {
    name: sku
    tier: tier
  }
  dependsOn: []
}
