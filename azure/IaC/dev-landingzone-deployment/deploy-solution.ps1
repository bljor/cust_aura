<#
    Script der styrer deployment af infrastruktur i en ny landingzone samt sørger for oprettelse af relaterede elementer
    i central hub landing zone

    I den centrale landing zone mangler oprettelse af:
    - firewall regler for den nye landing zone
    - app gateway skal konfigureres (men før det kan ske, skal der være deployet kode til containers)
    - der skal laves DNS records i Private DNS central landing zone (nuværende hes-sandbox) (den skal flyttes fra hes-sandbox til platform)
    - disse kan først laves når der er deployet container app kode og nødvendige hostnavne er kendt
    - DNS konfiguration kan laves vha. dns-records.bicep, men skal deployes manuelt - eller tilføjes sidst i scriptet

#>

$newLandingZoneId = "692a57dc-fed3-4ff6-a5d7-7ed5a11a2240"               # ID på subscription der skal deployes til (smile-fointegration-sub-nonproduction-dinel)
$hubLandingZoneId = "0d742875-267e-4db3-8a2b-10891ce92a5c"               # ID på hub subscription (hvortil der laves peering)

$resgroupName = "fointegration"                                          # resource group der deployes til
$resgroupExtension = "-rg-d-dinel"                                       # extension på resource group name (jf. navngivningsstandard)
$resLocation = "westeurope"                                              # alt infrasturktur hos Aura/Dinel deployes til westeurope
# $adminPassword = -join([char[]](40..122) | Get-Random -Count 24)
$adminPassword = "123afdshjirqerqy874#%jkadsSJAKJ"                       # administrator password til VM


# switch to new subscription
az account set --subscription $newLandingZoneId

# 1. create the resource group
az group create --name "$resgroupName-infrastructure$resgroupExtension" --location $resLocation --tags Environment="Dev" CostCenter="Dinel" OpsTeam="IT-Drift"
az group create --name "$resgroupName$resgroupExtension" --location $resLocation --tags Environment="Dev" CostCenter="Dinel" OpsTeam="IT-Drift"

# 2. deploy the custom role for granting access to join subnets
az deployment sub create --location $resLocation --name "Deploy-custom-role-AURA-Network-VirtualNetworks-Subnets-Join" --template-file "smile-custom-roles.bicep"



# 3. deploy the infrastructure
az deployment group create --resource-group "$resgroupName-infrastructure$resgroupExtension" --template-file .\smile-fsintegration-infrastructure.bicep --parameters adminPassword=$adminPassword developersResourceGroup="$resgroupName$resgroupExtension"



# switch to hub subscription
az account set --subscription $hubLandingZoneId

# the smile-fsintegration-platform.bicep is currently empty - contains nothing to deploy
# az deployment group create --resource-group "hub-subscription" --template-file .\smile-fsintegration-platform.bicep

# switch back to new subscription
az account set --subscription $newLandingZoneId


