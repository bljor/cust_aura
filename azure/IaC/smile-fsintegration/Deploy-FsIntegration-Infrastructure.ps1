$ResourceGroupName = "extbjo-rg-d-dinel"
$location = "westeurope"
$tagCostCenter = "Dinel"
$tagEnvironment = "Dev"
$tagOpsTeam = "IT-Drift"

$tags = {environment=$tagEnvironment costCenter=$tagCostCenter opsTeam=$tagOpsTeam}

write-host $tags
# az group create --name $ResourceGroupName --location $location --tags $tags
# az deployment group create --resource-group $ResourceGroupName --template-file .\smile-fsintegration-vm.bicep --parameters adminUsername="adminbjo"

