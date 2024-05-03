<# 
# ------------------------------------------------------------------------------------------#
# Date: 10/006-2021
# Purpose: Get Computers in OU and add them to a security group 
# Author: JEH
# Changed - date: 
# Source: 
# ------------------------------------------------------------------------------------------#
#>


Import-Module ActiveDirectory

$Comps = Get-ADcomputer -SearchBase 'OU=IT,OU=Forretningsservice,OU=Computers,OU=AURA Computers,DC=aura,DC=dk' -filter *
Add-ADGroupMember -Identity 'SG_Device-Install-DefenderForEndpoint' -Members $Comps