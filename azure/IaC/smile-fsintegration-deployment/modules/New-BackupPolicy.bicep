param backupPolicyName string


// Denne vil have nogle udfordringer ... Property parent: recoveryServicesVault vil ikke fungere eftersom denne er oprettet via et andet modul

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
    timeZone: 'UTC'             // kunne måske også være 'Romance Standard Time'
  }
}
