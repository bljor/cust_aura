#  Introduktion

Disse scripts anvendes til deployment af udviklingsmiljøet til FO-Integration som en del af SMILE projektet.


# Hvordan deployer jeg miljøet?

1. Download scripts til en lokal folder
2. Login til Azure med kommandoen az login
3. Check indholdet af deploy-solution.ps1
4. Verificér at variablen $newLandingZoneId har ID'et på det subscription der skal deployes til (smile-fointegration-sub-nonproduction-dinel)
5. Verificér at variablen $hubLandingZoneId har ID'et på platform subscription (som indeholder det centrale vnet)
6. Check indholdet af smile-fsintegration-infrastructure.bicep, alle variabler indtil linje 117 hvor bicep ressourcer starter. Nogle af disse variabler skal ændres - afhængig af deployment.
7. Kør PowerShell scriptet deploy-solution.ps1



# Udeståender som pt. ikke er løst?

Denne deployment bør køre igennem uden fejl, når IT-Drift deployer. Når udviklerne efterfølgende deployer kode og container envrionment, så er der nogle ting som vil fejle.

1. Der mangler en resource provider på subscription Microsoft.OperationalInsights
2. Udviklere kan ikke forbinde container environment til de vnet der er oprettet, de mangler rettighederne:
Microsoft.Network/virtualNetworks/read
Microsoft.Network/virtualNetworks/subnets/join/action


