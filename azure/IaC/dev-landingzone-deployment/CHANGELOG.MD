Missing fixes / changes:
- added functionality to ensure that required resource providers are registered in the subscription


2024-07-02	Version 1.1
		
		- creation of custom RBAC role for granting join access to virtualNetwork/subnets (smile-custom-roles.bicep)
		- added the custom role to the deployment script under step 2. deploy the custom role for granting access to join subnets
		- assigning the custom RBAC role to the Developers group of the subscription


2024-07-02	Original deployment
