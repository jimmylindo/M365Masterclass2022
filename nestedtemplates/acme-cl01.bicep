@description('Size of VM')
param vmSize string = 'Standard_B2s'

@description('The FQDN of the AD domain')
param domainToJoin string = 'corp.acme.com'


@description('Organizational Unit path in which the nodes and cluster will be present.')
param ouPath string = 'OU=Computers; OU=ACME; DC=corp; DC=acme; DC=com'

@description('Set of bit flags that define the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx')
param domainJoinOptions int = 3

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
var ComputerName_var = 'ACME-CL01'
var NetworkInterfaceName_var = 'ACME-CL01-Nic'
var PrivateIP_var = '10.0.0.6'

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
              id: '${loadbalancer_resource.id}/inboundNatRules/ACMECL01-NATRuleRDP'
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

resource ACME_CL01_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: 'ACME-CL01/JoinDomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: '${domainToJoin}\\${adminUsername}'
      restart: true
      options: domainJoinOptions
    }
    protectedSettings: {
      Password: adminPassword
    }
  }
  dependsOn: [
    ComputerName
  ]
}
