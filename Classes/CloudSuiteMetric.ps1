# class to hold Tenant metrics
class CloudSuiteMetric
{
	[System.Int32]$ServersCountTotal
	[System.Int32]$AccountsCountTotal
	[System.Int32]$SecretsCountTotal
	[System.Int32]$SetsCountTotal
	[System.Int32]$DomainCountTotal
	[System.Int32]$CommandCountTotal
	[System.Int32]$AppCountTotal
	[System.Int32]$CentrifyClientCountTotal
	[System.Int32]$RoleCountTotal
	[System.Int32]$ConnectorCountTotal
	hidden [PSCustomObject]$CloudSuiteData
	hidden [PSCustomObject]$Version

	CloudSuiteMetric($data, $version)
	{

		$this.CloudSuiteData = $data
        $this.Version = $version

        # server metrics
        $this.addCount("OperatingSystem","Servers","ServerCountBy_OS")
        $this.addCount("ComputerClass","Servers","ServerCountBy_ComputerClass")
        $this.addCount("LastState","Servers","ServerCountBy_LastState")
        $this.addCount("HealthStatus","Servers","ServerCountBy_HealthStatus")
        $this.ServersCountTotal = $this.CloudSuiteData.Servers | Measure-Object | Select-Object -ExpandProperty Count

        # account metrics
        $this.addCount("Healthy","Accounts","AccountCountBy_Health")
        $this.AccountsCountTotal = $this.CloudSuiteData.Accounts | Measure-Object | Select-Object -ExpandProperty Count
        
        # secret metrics
        $this.addCount("Type","Secrets","SecretsCountBy_Type")
        $this.SecretsCountTotal = $this.CloudSuiteData.Secrets | Measure-Object | Select-Object -ExpandProperty Count

        # set metrics
        $this.addCount("ObjectType","Sets","SetsCountBy_ObjectType")
        $this.addCount("CollectionType","Sets","SetsCountBy_CollectionType")
        $this.SetsCountTotal = $this.CloudSuiteData.Sets | Measure-Object | Select-Object -ExpandProperty Count

        # domain metrics
        $this.addCount("LastState","Domains","DomainsCountBy_LastState")
        $this.DomainCountTotal = $this.CloudSuiteData.Sets | Measure-Object | Select-Object -ExpandProperty Count

        # command metrics
        $this.CommandCountTotal = $this.CloudSuiteData.Commands | Measure-Object | Select-Object -ExpandProperty Count

        # app metrics
        $this.addCount("State","Apps","AppsCountBy_State")
        $this.addCount("AppType","Apps","AppsCountBy_AppType")
        $this.addCount("Category","Apps","AppsCountBy_Category")
        $this.AppCountTotal = $this.CloudSuiteData.Apps | Measure-Object | Select-Object -ExpandProperty Count

        # centrifyclient metrics
        $this.CentrifyClientCountTotal = $this.CloudSuiteData.CentrifyClients | Measure-Object | Select-Object -ExpandProperty Count

        # role metrics
        $this.RoleCountTotal = $this.CloudSuiteData.Roles | Measure-Object | Select-Object -ExpandProperty Count

        # connector metrics
        $this.addCount("Version","Connectors","ConnectorsCountBy_Version")
        $this.ConnectorCountTotal = $this.CloudSuiteData.Connectors | Measure-Object | Select-Object -ExpandProperty Count
	}# CloudSuiteMetric($data, $version)

	addCount($property, $obj, $counttext)
    {
        # count by property
        foreach ($i in ($this.CloudSuiteData.$obj | Select-Object -ExpandProperty $property -Unique))
        {
            $this | Add-Member -MemberType NoteProperty -Name ("{0}_{1}" -f $counttext, ($i -replace " ","_")) -Value ($this.CloudSuiteData.$obj | Where-Object {$_.$property -eq $i} | Measure-Object | Select-Object -ExpandProperty Count)
        }
    }# addCount($property, $obj, $counttext)

	[System.Double]getTotalFileSize()
    {
        $filesecrets = $this.CloudSuiteData.Secrets | Where-Object {$_.Type -eq "File"}

        [System.Double]$filesizetotal = 0

        foreach ($filesecret in $filesecrets)
        {
            [System.Double]$size = $filesecret.SecretFileSize -replace '\s[A-Z]+',''
            
            Switch -Regex (($filesecret.SecretFileSize -replace '^[\d\.]+\s([\w]+)$','$1'))
            {
                '^B$'  { $filesizetotal += $size; break }
                '^KB$' { $filesizetotal += ($size * 1024); break }
                '^MB$' { $filesizetotal += ($size * 1048576); break }
                '^GB$' { $filesizetotal += ($size * 1073741824); break }
                '^TB$' { $filesizetotal += ($size * 1099511627776); break }
            }
        }# foreach ($filesecret in $filesecrets)
        return $filesizetotal
    }# [System.Double]getTotalFileSize()
}# class CloudSuiteMetric