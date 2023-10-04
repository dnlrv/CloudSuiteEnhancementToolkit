# class to hold PasswordProfiles
class CloudSuitePasswordProfile
{
    [System.String]$Name
    [System.String]$ID
	[System.String]$Description
	[System.String]$SpecialCharSet
	[System.String]$FirstCharacterType
	[System.Boolean]$ConsecutiveCharRepeatAllowed
	[System.Boolean]$AtLeastOneSpecial
	[System.Boolean]$AtLeastOneDigit
	[System.Int32]$MinimumPasswordLength
	[System.Int32]$MaximumPasswordLength
	[System.String]$ProfileType

    CloudSuitePasswordProfile($p)
    {
        $this.Name                         = $p.Name
        $this.ID                           = $p.ID
		$this.Description                  = $p.Description
		$this.SpecialCharSet               = $p.SpecialCharSet
		$this.FirstCharacterType           = $p.FirstCharacterType
		$this.ConsecutiveCharRepeatAllowed = $p.ConsecutiveCharRepeatAllowed
		$this.AtLeastOneSpecial            = $p.AtLeastOneSpecial
		$this.AtLeastOneDigit              = $p.AtLeastOneDigit
		$this.MinimumPasswordLength        = $p.MinimumPasswordLength
		$this.MaximumPasswordLength        = $p.MaximumPasswordLength
		$this.ProfileType                  = $p.ProfileType
    }# CloudSuitePasswordProfile($p)
}# class CloudSuitePasswordProfile
