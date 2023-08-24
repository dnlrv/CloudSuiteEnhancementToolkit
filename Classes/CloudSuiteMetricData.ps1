# class to hold Tenant metric data
class CloudSuiteMetricData
{
	[PSCustomObject]$Servers
    [PSCustomObject]$Accounts
    [PSCustomObject]$Secrets
    [PSCustomObject]$Sets
    [PSCustomObject]$Domains
    [PSCustomObject]$Commands
    [PSCustomObject]$Apps
    [PSCustomObject]$CentrifyClients
    [PSCustomObject]$Roles
    [PSCustomObject]$Connectors
    
    CloudSuiteMetricData($s,$a,$sec,$set,$d,$c,$ap,$cc,$r,$con)
    {
        $this.Servers = $s
        $this.Accounts = $a
        $this.Secrets = $sec
        $this.Sets = $set
        $this.Domains = $d
        $this.Commands = $c
        $this.Apps = $ap
        $this.CentrifyClients = $cc
        $this.Roles = $r
        $this.Connectors = $con
    }# CloudSuiteMetricData($s,$a,$sec,$set,$d,$c,$ap,$cc,$r,$con)
}# class CloudSuiteMetricData