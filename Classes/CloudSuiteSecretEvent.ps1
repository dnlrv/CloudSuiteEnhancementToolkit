
# class to hold CloudSuiteSecretEvents
class CloudSuiteSecretEvent
{
	[System.String]$EventType
	[System.String]$Message
	[System.String]$User
	[System.DateTime]$whenOccurred

	CloudSuiteSecretEvent() {}
}# class CloudSuiteSecretEvent
