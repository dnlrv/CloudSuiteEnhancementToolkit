
# class to hold CloudSuiteSetEvents
class CloudSuiteSetEvent
{
	[System.String]$EventType
	[System.String]$Message
	[System.String]$User
	[System.DateTime]$whenOccurred

	CloudSuiteSetEvent() {}

	CloudSuiteSetEvent($e)
	{
		$this.EventType    = $e.EventType
		$this.Message      = $e.Message
		$this.User         = $e.User
		$this.whenOccurred = $e.whenOccurred 
	}
}# class CloudSuiteSetEvent
