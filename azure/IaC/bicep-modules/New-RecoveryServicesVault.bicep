// Recovery Services Vault til lagring og opbevaring af backup, der konfigureres for virtuelle maskiner

param location string = resourceGroup().location
param rsvName string
param backupPolicyName string

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: rsvName
  location: location
  tags: {
    OpsTeam: 'IT-Drift'
    CostCenter: 'Dinel'
    Envrionment: 'Dev'
  }
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    securitySettings: {
      immutabilitySettings: {
        state: 'Disabled'
      }
    }
  }
}

// Backup Policy som styrer hvordan backup laves. Relateret til Recovery Services ovenfor
resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-04-01' = {

  name: backupPolicyName
  location: resourceGroup().location

  tags: {
    OpsTeam: 'IT-Drift'
    CostCenter: 'Dinel'
    Environment: 'Dev'
  }
  parent: recoveryServicesVault

  properties: {
    backupManagementType: 'AzureIaasVM'
    
    instantRPDetails: {
      azureBackupRGNamePrefix: null
      azureBackupRGNameSuffix: null
    }
    instantRpRetentionRangeInDays: 2
    policyType: 'V2'
    
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
        retentionTimes: ['2024-06-04T19:00:00+00:00']
      }
      monthlySchedule: null
      weeklySchedule: null
      yearlySchedule: null
    }
    
    schedulePolicy: {
      dailySchedule: null
      hourlySchedule: {
        interval: 4
        scheduleWindowDuration: 12
        scheduleWindowStartTime: '2024-06-04T19:00:00+00:00'
      }
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Hourly'
      weeklySchedule: null
    }
    timeZone: 'UTC'
  }
}
