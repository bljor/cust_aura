// Recovery Services Vault til lagring og opbevaring af backup, der konfigureres for virtuelle maskiner
resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: 'extbjo-recoveryservices'
  location: resourceGroup().location
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

// Backup Policy skrevet fra bunden, med udgangspunkt i Microsoft dokumentation.
// name: 'extbjo-backup-policy-name'
// location: resourceGroup().location
// parent: recoveryServicesVault
//   tags: {
//   OpsTeam: 'IT-Drift'
//   CostCenter: 'Dinel'
//   Environment: 'Dev'


resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-03-01' = {

  parent: recoveryServicesVault
  name: 'extbjo-backup-policy-name'
  location: resourceGroup().location

  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5

    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: ['2024-06-04T19:00:00Z']
      schedulePolicyType: 'SimpleSchedulePolicy'
    }

    retentionPolicy: {
      dailySchedule: {
        retentionTimes: ['2024-06-04T19:00:00Z']
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
          'Saturday'
        ]
        retentionTimes: ['2024-06-04T19:00:00Z']
        retentionDuration: {
          count: 12
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: ['2024-06-04T19:00:00Z']
        retentionDuration: {
          count: 60
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: [
          'January'
          'February'
          'March'
          'April'
          'May'
          'June'
          'July'
          'August'
          'September'
          'October'
          'November'
          'December'
        ]
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: ['2024-06-04T19:00:00Z']
        retentionDuration: {
          count: 2
          durationType: 'Years'
        }
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
    }
    timeZone: 'UTC'
  }

}
