/*
  Alt der skal deployes til platform subscription placeres i denne bicep

  Opgaver i "det centrale subscription"
  - der skal laves firewall regler til fsintegration platformen
  - der skal laves konfiguration af app gateway
  - der skal laves DNS records i Private DNS i hes-sandbox subscription (den skal flyttes fra hes-sandbox til platform)
    Kan være en udfordring... Måske må de deployes med az cli istedet (se kommandoer i deploy-solution.ps1)

*/

var dnszonename = 'dev.fs.api.private.aura.dk'

resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnszonename
}

var dnshostname = 'www1'
var dnsip = '10.10.10.10'
var dnsttl = 3600

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


/*

    DOKUMENTATION:
    https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones?pivots=deployment-language-bicep
    https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones/a?pivots=deployment-language-bicep

    EKSEMPLER PÅ OPRETTELSEA AF ANDRE RECORDS


// Oprettelse af en Cname record

var dnszonename = 'dev.fs.api.private.aura.dk'
var dnshostname = www
var dnscname = 'loadbalancer.{$dnszonename}'

resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnszonename
}

resource dnsCnameRecord 'Microsoft.Network/privateDnsZones/CNAME@2020-06-01' = {
  name: dnshostname
  parent: dnszone
  properties: {
    cnameRecord: {
      cname: dnscname
    }
  }
}

*/
