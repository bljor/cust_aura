// Recovery Services Vault til lagring og opbevaring af backup, der konfigureres for virtuelle maskiner
resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-01-01' = {
  name: 'extbjo-recoveryservices'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

// Backup Policy som styrer hvordan backup laves. Relateret til Recovery Services ovenfor
resource OldbackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  name: 'old-extbjo-backup-policy-name'
  location: resourceGroup().location
  tags: {
    opsTeam: 'IT-Drift'
    costCenter: 'Dinel'
    Environment: 'Dev'
  }

  parent: recoveryServicesVault
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 7
    policyType: 'V2'
//    tieringPolicy: {}
    timeZone: 'UTC'

    instantRPDetails: {
      azureBackupRGNamePrefix: 'backup-prefix'
      azureBackupRGNameSuffix: 'backup-suffix'
    }

    retentionPolicy: {
      retentionPolicyType: 'SimpleRetentionPolicy'

      retentionDuration: {
        count: 30
        durationType: 'Days'
      }
    }

    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes: [
            '2024-06-03T19:00:00Z'
          ]
      }
      hourlySchedule: {}
      weeklySchedule: {}
    }

  }

}
