// Recovery Services Vault til lagring og opbevaring af backup, der konfigureres for virtuelle maskiner
resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: 'rv-extbjo'
  location: resourceGroup().location
  tags: {
    OpsTeam: 'IT-Drift'
    CostCenter: 'Dinel'
    Environment: 'Dev'
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
  }
}

// Backup Policy som styrer hvordan backup laves. Relateret til Recovery Services ovenfor
resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-04-01' = {

  name: 'extbjo-backup-policy'
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
      azureBackupRGNamePrefix: 'prefix'
      azureBackupRGNameSuffix: 'suffix'
    }
    instantRpRetentionRangeInDays: 5
    policyType: 'V2'
    
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
        retentionTimes: ['2024-06-04T19:00:00Z']
      }
      monthlySchedule: {
        retentionDuration: {
          count: 60
          durationType: 'Months'
        }
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionScheduleFormatType: 'Daily'
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Monday'
            'Tuesday'
            'Wednesday'
            'Thursday'
            'Friday'
            'Saturday'
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
            'Fourth'
            'Invalid'
            'Last'
            'Second'
            'Third'
          ]
        }
        retentionTimes: ['2024-06-04T19:00:00Z']
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
        retentionDuration: {
          count: 12
          durationType: 'Weeks'
        }
        retentionTimes: ['2024-06-04T19:00:00Z']
      }
      yearlySchedule: {
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
        retentionDuration: {
          count: 2
          durationType: 'Years'
        }
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionScheduleFormatType: 'Daily'
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Monday'
            'Tuesday'
            'Wednesday'
            'Thursday'
            'Friday'
            'Saturday'
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
            'Fourth'
            'Invalid'
            'Last'
            'Second'
            'Third'
          ]
        }
        retentionTimes: ['2024-06-04T19:00:00Z']
      }
    }
    
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      hourlySchedule: {
        interval: 8
        scheduleWindowDuration: 24
        scheduleWindowStartTime: '19:00'
      }
      scheduleRunDays: [
        'Monday'
        'Tuesday'
        'Wednesday'
        'Thursday'
        'Friday'
        'Saturday'
        'Sunday'
      ]
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: ['2024-06-04T19:00:00Z']
      scheduleWeeklyFrequency: 1
    }
    timeZone: 'UTC'
  }
}
