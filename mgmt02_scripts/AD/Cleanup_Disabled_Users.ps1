<# 
# ------------------------------------------------------------------------------------------#
# Date: 21/05-2021
# Purpose: Cleanup Disabled users. 
# Author: JEH
# Changed - date: 
# Source: 
# ------------------------------------------------------------------------------------------#
#>


Import-Module ActiveDirectory

# This line removes attributes from users in disabled Users OU 
Get-ADUser -Filter * -SearchBase 'OU=Disabled,OU=AURA Users,DC=aura,DC=dk'  | Set-ADUser -clear 'telephoneNumber','homePhone', 'pager', 'mobile', 'facsimileTelephoneNumber', 'ipPhone', 'Manager'



# This script removes all disabled users from all security and distribution groups in the specified "searchOU"

foreach ($username in (Get-ADUser -SearchBase "OU=Disabled,OU=AURA Users,DC=aura,DC=dk" -filter *)) {
 
# Get all group memberships
$groups = get-adprincipalgroupmembership $username;
 
# Loop through each group
foreach ($group in $groups) {
 
    # Exclude Domain Users group
    if ($group.name -ne "domain users") {
 
        # Remove user from group
        remove-adgroupmember -Identity $group.name -Member $username.SamAccountName -Confirm:$false;
 
        # Write progress to screen
        write-host "removed" $username "from" $group.name;
 
        # Define and save group names into filename in C:\Scripts\Log\groupsstrip
        $grouplogfile = "C:\Scripts\Log\groupsstrip\" + $username.SamAccountName + ".txt";
        $group.name >> $grouplogfile
    }
 
}
}