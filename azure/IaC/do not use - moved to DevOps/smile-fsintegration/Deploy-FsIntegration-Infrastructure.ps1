$ResourceGroupName = "extbjo-rg-d-dinel"
$location = "westeurope"
$tagCostCenter = "Dinel"
$tagEnvironment = "Dev"
$tagOpsTeam = "IT-Drift"
$adminUsername="adminbjo"
$adminPassword="jadsfOIUARafsdj78324#fdaUI"

# -join([char[]](33..122) | Get-Random -Count 24)

$tags = @"
{
    "environment": "$tagEnvironment",
    "costCenter": "$tagCostCenter",
    "opsTeam": "$tagOpsTeam"
}
"@

az group create --name $ResourceGroupName --location $location --tags Environment=$tagEnvironment CostCenter=$tagCostCenter OpsTeam=$tagOpsTeam
az deployment group create --resource-group $ResourceGroupName --template-file .\smile-fsintegration-vm.bicep --parameters adminUsername=$adminUsername adminPassword=$adminPassword location=$location


