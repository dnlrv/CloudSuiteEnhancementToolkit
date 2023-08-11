# class to hold CloudSuiteConnections
class CloudSuiteConnection
{
    [System.String]$PodFqdn
    [PSCustomObject]$CloudSuiteConnection
    [System.Collections.Hashtable]$CloudSuiteSessionInformation

    CloudSuiteConnection($po,$pc,$s)
    {
        $this.PodFqdn                      = $po
        $this.CloudSuiteConnection         = $pc
        $this.CloudSuiteSessionInformation = $s
    }
}# class CloudSuiteConnection