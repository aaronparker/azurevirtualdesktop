
@description('Tags parameter input file.')
var tags = json(loadTextContent('../params/tags.json'))

@allowed([
  'Azure Virtual Desktop'
  'Nerdio Manager'
])
param application string = 'Azure Virtual Desktop'

@allowed([
  'High'
  'Medium'
  'Low'
])
param criticality string = 'High'

@description('The environment to deploy the resources to')
@allowed([
  'Development'
  'Test'
  'Acceptance'
  'Production'
])
param environment string = 'Production'

@description('The cost center to charge the resources to')
param costCenter string = '123456'

@description('The function of the resources')
param function string = 'Pooled desktop'

@description('The UPN of the user who last updated the resources')
param upn string

@description('The owner of the resources')
param owner string = 'stealthpuppy'

@description('The type of the resources')
param type string = 'Session hosts'

@description('Deployment date in yyyy-MM-dd format')
param date string = utcNow('yyyy-MM-dd')

var tagsObject = {
  Application: application
  Criticality: criticality
  Environment: environment
  Function: function
  LastUpdateBy: upn
  LastUpdateDate: date
  Owner: owner
  CostCenter: costCenter
  Type: type
}

output Tags object = tagsObject
