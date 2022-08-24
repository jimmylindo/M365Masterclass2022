@description('The name of the administrator account of the new VM and domain')
param adminUsername string = 'sysadmin'

@description('The password for the administrator account of the new VM and domain')
@secure()
param adminPassword string = 'Passw0rd1234!'

@description('The FQDN of the Active Directory Domain to be created')
param domainName string = 'CORP.ACME.COM'

@description('Size of the VM for the controller')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Virtual machine name.')
param virtualMachineName string = 'ACME-dc01'

@description('Virtual network name.')
param virtualNetworkName string = 'ACME-VNet1'

@description('Virtual network address range.')
param virtualNetworkAddressRange string = '10.0.0.0/16'

@description('Network interface name.')
param networkInterfaceName string = 'ACME-dc01-nic1'

@description('Private IP address.')
param privateIPAddress string = '10.0.0.4'

@description('Subnet name.')
param subnetName string = 'adds-subnet'

@description('Subnet IP range.')
param subnetRange string = '10.0.0.0/24'

@description('Availability set name.')
param availabilitySetName string = 'ACME-dc-advset1'

@description('The location of resources such as templates and DSC modules that the script is dependent')
param assetLocation_dc01 string = 'https://raw.githubusercontent.com/jimmylindo/M365Masterclass2022/main/ACME-DC01Config/'

@description('The location of resources such as templates and DSC modules that the script is dependent')
param assetLocation_CreateADForest string = 'https://raw.githubusercontent.com/jimmylindo/M365Masterclass2022/main/DSC/'


resource availabilitySetName_resource 'Microsoft.Compute/availabilitySets@2019-03-01' = {
  location: location
  name: availabilitySetName
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

module VNet './nestedtemplates/vnet.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nestedtemplates/vnet.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'VNet'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: subnetName
    subnetRange: subnetRange
    location: location
  }
}

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
        }
      }
    ]
  }
  dependsOn: [
    VNet
  ]
}

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    availabilitySet: {
      id: availabilitySetName_resource.id
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'Latest'
      }
      osDisk: {
        name: '${virtualMachineName}_OSDisk'
        caching: 'ReadOnly'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          name: '${virtualMachineName}_DataDisk'
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 20
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
          lun: 0
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
  }
}

resource virtualMachineName_CreateADForest 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  parent: virtualMachineName_resource
  name: 'CreateADForest'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: false
    settings: {
      ModulesUrl: '${assetLocation_CreateADForest}CreateADPDC.zip'
      ConfigurationFunction: 'CreateADPDC.ps1\\CreateADPDC'
      Properties: {
        DomainName: domainName
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
}

resource ACME_DC01_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: 'ACME-DC01/CustomScript'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        '${assetLocation_dc01}acme-dc01.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File acme-dc01.ps1'
    }
  }
  dependsOn: [
    virtualMachineName_resource
    virtualMachineName_CreateADForest
  ]
}

module UpdateVNetDNS './nestedtemplates/vnet-with-dns-server.bicep' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nestedtemplates/vnet-with-dns-server.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'UpdateVNetDNS'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: subnetName
    subnetRange: subnetRange
    DNSServerAddress: [
      privateIPAddress
    ]
    location: location
  }
  dependsOn: [
    virtualMachineName_CreateADForest
  ]
}

module CreateACMECL01 './nestedtemplates/acme-cl01.bicep' ={
  name: 'DeployCL01'
  params: {
    virtualNetworkName: virtualNetworkName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetName: subnetName
    location: location
  }
  dependsOn: [
    UpdateVNetDNS
  ]
}
