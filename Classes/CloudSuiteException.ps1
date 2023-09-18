# class to hold a custom CloudSuiteError
class CloudSuiteException
{
	[System.String]$Message
	[System.String]$ErrorMessage
	[System.String]$FullyQualifiedErrorId
	[System.String]$Line
	[System.Int32]$LineNumber
	[System.Int32]$OffsetInLine
	[hashtable]$Data = @{}
	[System.Exception]$Exception
    [System.String]$APICall
    [System.String]$Payload
    [PSCustomObject]$Response

    CloudSuiteException([System.String]$m) 
	{
		$this.Message = $m

		$global:LastClousSuiteError = $this
	}

	addExceptionData([PSCustomObject]$e)
	{
		$this.ErrorMessage          = $e.Exception.Message
		$this.FullyQualifiedErrorId = $e.InnerException.ErrorRecord.FullyQualifiedErrorId
		$this.Line                  = $e.InnvocationInfo.Line
		$this.LineNumber            = $e.InnovcationInfo.ScriptLineNumber
		$this.OffsetInLine          = $e.InnovcationInfo.OffsetInLine
		$this.Exception             = $e
	}# addExceptionData([PSCustomObject]$e)

	addAPIData([PSCustomObject]$a, [PSCustomObject]$b, [PSCustomObject]$r)
	{
		$this.APICall = $a
		$this.Payload = $b
		$this.Reponse = $r
	}

	addData($k,$v)
	{
		$this.Data.$k = $v
	}

	<#
	# how to use
	Catch
	{
		$e = New-Object ScriptException -ArgumentList ("This errored here.")
		$e.AddAPIData($apicall, $payload, $response)
		$e.AddExceptionData($_)
	}
	#>
}# class CloudSuiteException