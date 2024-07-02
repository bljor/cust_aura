



resource agw 'Microsoft.Network/applicationGateways@2023-11-01' existing = {
  name: 'platform-gateway-agw-t-aura'
  scope: subscription('0d742875-267e-4db3-8a2b-10891ce92a5c') 

}
