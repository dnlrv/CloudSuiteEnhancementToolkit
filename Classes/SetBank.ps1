# class to hold SetBanks
class SetBank
{
    [System.String]$Type
	[System.Collections.ArrayList]$Sets = @{}

    SetBank([System.String]$t)
    {
        $this.Type = $t
    }

	addSets([PSCustomObject[]]$s)
	{
		$this.Sets.AddRange(@($s)) | Out-Null
	}

	removeSets([PSCustomObject[]]$s)
	{
		$this.Sets.RemoveRange(@($s)) | Out-Null
	}
}# class SetBank