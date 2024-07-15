This file documents requirements which must be in place for the deployment to succeed.


# Registration of resource providers on target subscription
The following Resource Providers must be registered on the subscription, if they are not present - they will be registered, but registration can be slow so you need to verify the registration before continuing to deploy the Container Environment.

- Microsoft.App
- Microsoft.Capacity
- Microsoft.ChangeAnalysis
- Microsoft.ContainerInstance
- Microsoft.OperationalInsights

# Changes that must be made to the functionality

Auto-generation of password for VM ... Use this code instead of the existing. It generates passwords without special characters.

-join([char[]](48..57+65..90+97..122) | Get-Random -Count 24)


# Add functionality to perform auto registration of resource providers as mentioned above



# Add functionality to find the correct groups in Entra ID (to use for Developers etc.)
