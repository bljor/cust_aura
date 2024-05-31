param location vmName = 'name of vm'
param sharedLocation = 'westeurope'


resource autoShutdownConfig 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: sharedLocation
  tags: {
    opsTeam: 'Name of Operations Team'
    costCenter: 'Name of Cost Center'
    environment: 'Name of environmen'
    // add more tags if necessary
  }
  properties: {
    dailyRecurrence: {
      time: '1900'
    }
    notificationSettings: {
      status: 'Disabled'
    }
    status: 'Enabled'
    timeZoneId: 'UTC'
    taskType: 'ComputeVmShutdownTask'
    targetResourceId: 'Id of the virtual machine the job should apply to'
  }
}
