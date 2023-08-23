
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

	CloudSuiteAccountEvent($e)
	{
		$this.EventType    = $e.EventType
		$this.Message      = $e.Message
		$this.SourceName   = $e.SourceName
		$this.AccountName  = $e.AccountName
		$this.User         = $e.User
		$this.whenOccurred = $e.whenOccurred 
	}
}# class CloudSuiteAccountEvent
