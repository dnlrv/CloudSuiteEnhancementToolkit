# class to hold a custom RowAce error
class CloudSuiteRowAceException : System.Exception
{
    [PSCustomObject]$RowAce
    [PSCustomObject]$CloudSuitePermission
    [System.String]$ErrorMessage

    CloudSuiteRowAceException([System.String]$message) : base ($message) {}

    CloudSuiteRowAceException() {}
}# class PlatformRowAceException : System.Exception