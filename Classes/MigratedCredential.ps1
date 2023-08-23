# class to hold a MigratedCredential
class MigratedCredential
{
    [System.String]$SecretTemplate
    [System.String]$SecretName
    [System.String]$Target
    [System.String]$Username
    [System.String]$Password
    [System.String]$Folder
    [System.Boolean]$hasConflicts
    [System.String]$PASDataType
    [System.String]$PASUUID
    [System.Collections.ArrayList]$memberofSets = @{}
    [System.Collections.ArrayList]$Permissions = @{}
    [System.Collections.ArrayList]$FolderPermissions = @{}
    [System.Collections.ArrayList]$SetPermissions = @{}
    [System.Collections.Hashtable]$Slugs
    [PSObject]$OriginalObject

    MigratedCredential() {}

    setSecretServerFolder([System.String]$FolderName)
    {
        $this.Folder = $FolderName
    }

	getCloudSuiteSetsThatIAmAMemberOf()
	{
		$queries = Query-RedRock -SQLQuery ("SELECT ID,Name FROM Sets WHERE ObjectType = '{0}' AND CollectionType = 'ManualBucket'" -f $this.PASDataType)

		foreach ($query in $queries)
		{
			$isMember = Invoke-CloudSuiteAPI -APICall Collection/IsMember -Body ( @{ID=$query.ID; Table=$this.PASDataType; Key=$this.PASUUID} | ConvertTo-Json)

			if ($isMember)
			{
				$this.memberOfSets.Add((Get-CloudSuiteSet -Uuid $query.ID)) | Out-Null
			}
		}# foreach ($query in $queries)

		$this.determineConflicts()
	}# getCloudSuiteSetsThatIAmAMemberOf()

	getCloudSuiteSetsThatIAmAMemberOf([PSCustomObject]$SetBank)
	{
		$memberof = $SetBank.Sets | Where-Object {$_.Members.Key -contains $this.PASUUID}

		foreach ($member in $memberof)
		{
			$this.memberofSets.Add((Get-CloudSuiteSet -Uuid $member.Uuid)) | Out-Null
		}

		$this.determineConflicts()
	}# getCloudSuiteSetsThatIAmAMemberOf()([PSCustomObject]$SetBank)

    determineConflicts()
    {
		if (($this.memberofSets | Measure-Object | Select-Object -ExpandProperty Count) -gt 1)
		{
			$this.hasConflicts = $true
		}
		else
		{
			$this.hasConflicts = $false
		}
    }# determineConflicts()

    SetSetPermissions($CloudSuiteSet)
    {
        foreach ($rowace in $CloudSuiteSet.PermissionRowAces)
        {
            $obj = ConvertTo-SecretServerPermission -Type Set -Name $CloudSuiteSet.Name -RowAce $rowace

            $this.SetPermissions.Add($obj) | Out-Null
        }
    }# SetSetPermission($CloudSuiteSet)

    SetFolderPermissions($CloudSuiteSet)
    {
        foreach ($rowace in $CloudSuiteSet.PermissionRowAces)
        {
            $obj = ConvertTo-SecretServerPermission -Type Folder -Name $CloudSuiteSet.Name -RowAce $rowace

            $this.FolderPermissions.Add($obj) | Out-Null
        }
    }# SetFolderPermissions($CloudSuiteSet)

    [System.Boolean] UnmanageAccount()
    {
        # if the account was successfully unmanaged
        if ($manageaccount = Invoke-CloudSuiteAPI ServerManage/UpdateAccount -Body (@{ID=$this.PASUUID;User=$this.Username;SourceType=$this.OriginalObject.SourceID;IsManaged=$false}|ConvertTo-Json))
        {
            $this.isManaged = $false
            return $true
        }
        return $false
    }# [System.Boolean] UnmanageAccount()

	[System.Boolean]CheckoutPassword()
	{
		if ($this.PASDataType -ne "VaultAccount")
		{
			throw ("This credential [{0}] is not a VaultAccount object" -f $this.SecretName)
		}

		if ($global:CloudSuiteEnableClearTextPasswordsAndSecrets -eq $false)
		{
			# if the global Encrypted Key is not set
			if (-Not ($global:CloudSuiteEncryptedKey))
			{
				Write-Warning ("No global encrypted key set. Use Set-CloudSuiteEncryptionKey to set one.")
				throw "`$CloudSuiteEnableClearTextPasswordsAndSecrets is `$false and no global key is set."
			}
			else # encrypted is true and key is set
			{
				# if checkout is successful
				if ($checkout = Invoke-CloudSuiteAPI -APICall ServerManage/CheckoutPassword -Body (@{ID = $this.PASUUID} | ConvertTo-Json))
				{   
					# set these checkout fields
					$pw = ConvertTo-SecureString -AsPlainText -Force -String $checkout.Password
					$this.Password = $pw | ConvertFrom-SecureString -Key $global:CloudSuiteEncryptedKey
				}# if ($checkout = Invoke-CloudSuiteAPI -APICall ServerManage/CheckoutPassword -Body (@{ID = $this.ID} | ConvertTo-Json))
				else
				{
					return $false
				}
				return $true
			}
		}# if ($global:CloudSuiteClearTextPasswordsAndSecrets -eq $false)
		else
		{
			# if checkout is successful
			if ($checkout = Invoke-CloudSuiteAPI -APICall ServerManage/CheckoutPassword -Body (@{ID = $this.PASUUID} | ConvertTo-Json))
			{   
				# set these checkout fields
				$this.Password = $checkout.Password
			}# if ($checkout = Invoke-CloudSuiteAPI -APICall ServerManage/CheckoutPassword -Body (@{ID = $this.ID} | ConvertTo-Json))
			else
			{
				return $false
			}
			return $true
		}# else
	}# [System.Boolean]CheckoutPassword()

	[System.String]decryptPassword($key)
	{
		# if the provided key doesn't exist
		if (-Not ($key))
		{
			Write-Warning ("No key provided. Use Set-CloudSuiteEncryptionKey -ReturnAsVariable to get one.")
			throw "No key provided."
		}

		Try # to convert this to plain text using the provided key
		{
			$pw = $this.Password | ConvertTo-SecureString -Key $key
			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw)
			$clearpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		}
		Catch [System.ArgumentNullException] # if $pw is null that is due to the key being invalid
		{
			throw "Key is invalid."
		}
		
		return $clearpassword
	}# [System.String]decryptPassword($key)

	[System.String]decryptPassword()
	{
		# if the global Encrypted Key is not set
		if (-Not ($global:CloudSuiteEncryptedKey))
		{
			Write-Warning ("No global encrypted key set. Use Set-CloudSuiteEncryptionKey to set one.")
			throw "No global encrypted key set."
		}

		Try # to convert this to plain text using the global key
		{
			$pw = $this.Password | ConvertTo-SecureString -Key $global:CloudSuiteEncryptedKey
			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw)
			$clearpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		}
		Catch [System.ArgumentNullException] # if $pw is null that is due to the key being invalid
		{
			throw "Key is invalid."
		}
		return $clearpassword
	}# [System.String]decryptPassword()

	# method to retrieve secret content
	[System.Boolean] RetrieveSecret()
	{
		if ($this.PASDataType -ne "DataVault")
		{
			throw ("This credential [{0}] is not a Secret object" -f $this.SecretName)
		}

		if ($global:CloudSuiteEnableClearTextPasswordsAndSecrets -eq $false)
		{
			# if the global Encrypted Key is not set
			if (-Not ($global:CloudSuiteEncryptedKey))
			{
				Write-Warning ("No global encrypted key set. Use Set-CloudSuiteEncryptionKey to set one.")
				throw "`$CloudSuiteEnableClearTextPasswordsAndSecrets is `$false and no global key is set."
			}
			else # encrypted is true and key is set
			{
				# if retrieve is successful
				if ($retrieve = Invoke-CloudSuiteAPI -APICall ServerManage/RetrieveSecretContents -Body (@{ ID = $this.PASUUID } | ConvertTo-Json))
				{   
					# set these SecretText fields
					$pw = ConvertTo-SecureString -AsPlainText -Force -String $retrieve.SecretText
					$this.Password = $pw | ConvertFrom-SecureString -Key $global:CloudSuiteEncryptedKey
				}# if ($retrieve = Invoke-CloudSuiteAPI -APICall ServerManage/RetrieveSecretContents -Body (@{ ID = $this.ID } | ConvertTo-Json))
				else
				{
					return $false
				}
				return $true
			}# else
		}# if ($global:CloudSuiteClearTextPasswordsAndSecrets -eq $false)
		else
		{
			# if retrieve is successful
			if ($retrieve = Invoke-CloudSuiteAPI -APICall ServerManage/RetrieveSecretContents -Body (@{ ID = $this.PASUUID } | ConvertTo-Json))
			{   
				# set these checkout fields
				$this.Password = $retrieve.SecretText
			}# if ($retrieve = Invoke-CloudSuiteAPI -APICall ServerManage/RetrieveSecretContents -Body (@{ ID = $this.ID } | ConvertTo-Json))
			else
			{
				return $false
			}
			return $true
		}# else
	
	return $false
	}# [System.Boolean] RetrieveSecret()

	[System.String] decryptSecret($key)
	{
		# if the provided key doesn't exist
		if (-Not ($key))
		{
			Write-Warning ("No key provided. Use Set-CloudSuiteEncryptionKey -ReturnAsVariable to get one.")
			throw "No key provided."
		}

		Try # to convert this to plain text using the provided key
		{
			$pw = $this.Password | ConvertTo-SecureString -Key $key
			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw)
			$clearsecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		}
		Catch [System.ArgumentNullException] # if $pw is null that is due to the key being invalid
		{
			throw "Key is invalid."
		}
		
		return $clearsecret
	}# [System.String]decryptSecret($key)

	[System.String] decryptSecret()
	{
		# if the global Encrypted Key is not set
		if (-Not ($global:CloudSuiteEncryptedKey))
		{
			Write-Warning ("No global encrypted key set. Use Set-CloudSuiteEncryptionKey to set one.")
			throw "No global encrypted key set."
		}

		Try # to convert this to plain text using the global key
		{
			$pw = $this.Password | ConvertTo-SecureString -Key $global:CloudSuiteEncryptedKey
			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw)
			$clearsecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		}
		Catch [System.ArgumentNullException] # if $pw is null that is due to the key being invalid
		{
			throw "Key is invalid."
		}
		return $clearsecret
	}# [System.String]decryptSecret()
}# class MigratedCredential
