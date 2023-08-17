
# class to hold CloudSuiteAccountEvents
class CloudSuiteAccountEvent
{
	[System.String]$EventType
	[System.String]$Message
	[System.String]$SourceName
	[System.String]$AccountName
	[System.String]$User
	[System.DateTime]$whenOccurred

	CloudSuiteAccountEvent() {}
}# class CloudSuiteAccountEvent
