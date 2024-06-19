resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {

  parent: recoveryServicesVault
  name: 'extbjo-backup-policy-name'
  location: resourceGroup().location

  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
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
