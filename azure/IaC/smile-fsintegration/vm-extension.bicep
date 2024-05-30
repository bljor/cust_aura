param vmName string
param location string

resource vmName_AADLogin 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/AADLogin'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}
