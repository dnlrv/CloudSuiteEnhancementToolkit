
# class to hold CloudSuiteSecretEvents
class CloudSuiteSecretEvent
{
	[System.String]$EventType
	[System.String]$Message
	[System.String]$User
	[System.DateTime]$whenOccurred

	CloudSuiteSecretEvent() {}

	CloudSuiteSecretEvent($e)
	{
		$this.EventType    = $e.EventType
		$this.Message      = $e.Message
		$this.User         = $e.User
		$this.whenOccurred = $e.whenOccurred
	}
}# class CloudSuiteSecretEvent
