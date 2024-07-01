/*
  
  Anvendes til oprettelse af A-records i en private DNS zone

*/

var dnszonename = 'dev.fs.api.private.aura.dk'
var dnshostname = 'www1'
var dnsip = '10.10.10.10'
var dnsttl = 3600

resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnszonename
}

// Oprettelse af en A-record
resource dnsrecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: dnshostname
  parent: dnszone
  properties: {
    aRecords: [
      {
        ipv4Address: dnsip
      }
    ]
    ttl: dnsttl
  }
}

