# class to hold a custom CloudSuiteAPIError
class CloudSuiteAPIException : System.Exception
{
    [System.String]$APICall
    [System.String]$Payload
    [System.String]$ErrorMessage
    [PSCustomObject]$Response

    CloudSuiteAPIException() {}

    CloudSuiteAPIException([System.String]$message) : base ($message) {}

}# class CloudSuiteAPIException : System.Exception