param publicIPAddresses_ACME_RDP_PIP_name string = 'ACME-RDP-PIP'

resource publicIPAddresses_ACME_RDP_PIP_name_resource 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: publicIPAddresses_ACME_RDP_PIP_name
  location: 'westeurope'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '3'
    '2'
    '1'
  ]
  properties: {
    ipAddress: '20.157.212.64'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: [
      {
        ipTagType: 'RoutingPreference'
        tag: 'Internet'
      }
    ]
  }
}