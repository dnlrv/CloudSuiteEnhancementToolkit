# class to hold Policy Options
class CloudSuitePolicyOption
{
	[System.String]$PolicyOption
	[System.String]$fromPolicy
	[PSObject]$PolicyValue

	CloudSuitePolicyOption([PSCustomObject]$po)
	{
		$this.PolicyOption = $po.PolicyOption
		$this.fromPolicy   = $po.fromPolicy
		$this.PolicyValue  = $po.PolicyValue
	}

	CloudSuitePolicyOption([System.String]$po, [System.String]$fp, [PSObject]$pv) 
	{
		$this.PolicyOption = $po
		$this.fromPolicy   = $fp
		$this.PolicyValue  = $pv
	}
}# class CloudSuitePolicyOption