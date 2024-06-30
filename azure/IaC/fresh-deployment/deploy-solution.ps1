<#
    Script der styrer deployment af infrastruktur i en ny landingzone samt sørger for oprettelse af relaterede elementer
    i central hub landing zone


    I den centrale landing zone mangler oprettelse af:
    - firewall regler for den nye landing zone
    - app gateway skal konfigureres (men før det kan ske, skal der være deployet kode til containers)
    - der skal laves DNS records i Private DNS central landing zone (nuværende hes-sandbox) (den skal flyttes fra hes-sandbox til platform)
    - disse kan først laves når der er deployet container app kode og nødvendige hostnavne er kendt

#>

$newLandingZoneId = "dbdf41de-2e24-433f-9062-1087a44de89e"
$hubLandingZoneId = "35bb3b04-a290-4f1a-a6c4-b86e154947f1"

$resgroupName = "container"
$resgroupExtension = "-rg-d-dinel"
$resLocation = "westeurope"
# $adminPassword = -join([char[]](40..122) | Get-Random -Count 24)
$adminPassword = "123afdshjirqerqy874#%jkadsSJAKJ"


# switch to new subscription        (Wipe.dk - Sponsored, dbdf41de-2e24-433f-9062-1087a44de89e)
az account set --subscription $newLandingZoneId

# 1. create the resource group
az group create --name "$resgroupName-infrastructure$resgroupExtension" --location $resLocation --tags Environment="Dev" CostCenter="Dinel" OpsTeam="IT-Drift"
az group create --name "$resgroupName$resgroupExtension" --location $resLocation --tags Environment="Dev" CostCenter="Dinel" OpsTeam="IT-Drift"

# 2. deploy the infrastructure
az deployment group create --resource-group "$resgroupName-infrastructure$resgroupExtension" --template-file .\smile-fsintegration-infrastructure.bicep --parameters adminPassword=$adminPassword developersResourceGroup="$resgroupName$resgroupExtension"



# switch to hub subscription        (Wipe.dk - Dev Subscription, 35bb3b04-a290-4f1a-a6c4-b86e154947f1)
az account set --subscription $hubLandingZoneId

# az deployment group create --resource-group "hub-subscription" --template-file .\smile-fsintegration-platform.bicep


az account set --subscription $newLandingZoneId