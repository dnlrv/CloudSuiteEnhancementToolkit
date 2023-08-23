# class to hold Accounts
class CloudSuiteAccount
{
    [System.String]$AccountType
    [System.String]$ComputerClass
    [System.String]$SourceName
    [System.String]$SourceType
    [System.String]$SourceID
    [System.String]$Username
    [System.String]$ID
    [System.Boolean]$isManaged
    [System.String]$Healthy
    [System.DateTime]$LastChange
    [System.DateTime]$LastHealthCheck
    [System.String]$Password
    [System.String]$Description
    [PSCustomObject[]]$PermissionRowAces           # The RowAces (Permissions) of this Account
    [System.Boolean]$WorkflowEnabled
    [PSCustomObject[]]$WorkflowApprovers # the workflow approvers for this Account
    [PSCustomObject]$Vault
    [System.String]$SSName
    [System.String]$CheckOutID
	[System.Collections.ArrayList]$AccountEvents = @{}

    CloudSuiteAccount() {}

    CloudSuiteAccount($account, [System.String]$t)
    {
       
        $this.AccountType = $t
        $this.ComputerClass = $account.ComputerClass
        $this.SourceName = $account.Name

        # the tenant holds the source object's ID in different columns
        Switch ($this.AccountType)
        {
            "Database" { $this.SourceID = $account.DatabaseID; $this.SourceType = "DatabaseId"; break }
            "Domain"   { $this.SourceID = $account.DomainID; $this.SourceType = "DomainId"; break }
            "Local"    { $this.SourceID = $account.Host; $this.SourceType = "Host"; break }
            "Cloud"    { $this.SourceID = $account.CloudProviderID; $this.SourceType = "CloudProviderId"; break }
        }

        # accounting for null
        if ($account.LastHealthCheck -ne $null)
        {
            $this.LastHealthCheck = $account.LastHealthCheck
        }

        # accounting for null
        if ($account.LastChange -ne $null)
        {
            $this.LastChange = $account.LastChange
        }

        $this.Username = $account.User
        $this.ID = $account.ID
        $this.isManaged = $account.IsManaged
        $this.Healthy = $account.Healthy
        $this.Description = $account.Description
        $this.SSName = ("{0}\{1}" -f $this.SourceName, $this.Username)

        # Populate the Vault property if Account is imported from a Vault
        if ($account.VaultId -ne $null)
        {
            $this.Vault = (Get-CloudSuiteVault -Uuid $account.VaultId)
        } # if ($null -ne $account.VaultId)
        else
        {
            $this.Vault = $null
        }
        
        # getting the RowAces for this Set
        $this.PermissionRowAces = Get-CloudSuiteRowAce -Type $this.AccountType -Uuid $this.ID

        # getting the WorkflowApprovers for this secret
        $this.WorkflowEnabled = $account.WorkflowEnabled
        
        # getting the WorkflowApprovers for this Account
        if ($this.WorkflowEnabled)
        {
            $this.WorkflowApprovers = Prepare-WorkflowApprovers -Approvers ($account.WorkflowApproversList | ConvertFrom-Json)
        }

    }# CloudSuiteAccount($account)

    [System.Boolean] CheckInPassword()
    {
        # if CheckOutID isn't null
        if ($this.CheckOutID -ne $null)
        {
            # if checkin is successful
            if ($checkin = Invoke-CloudSuiteAPI -APICall ServerManage/CheckinPassword -Body (@{ID = $this.CheckOutID} | ConvertTo-Json))
            {
                $this.Password   = $null
                $this.CheckOutID = $null
            }
            else
            {
                return $false
            }
        }# if ($this.CheckOutID -ne $null)
        else
        {
            return $false
        }
        return $true 
    }# [System.Boolean] CheckInPassword()

    [System.Boolean] UnmanageAccount()
    {
        # if the account was successfully unmanaged
        if ($manageaccount = Invoke-CloudSuiteAPI ServerManage/UpdateAccount -Body (@{ID=$this.ID;User=$this.Username;$this.SourceType=$this.SourceID;IsManaged=$false}|ConvertTo-Json))
        {
            $this.isManaged = $false
            return $true
        }
        return $false
    }# [System.Boolean] UnmanageAccount()

    [System.Boolean] ManageAccount()
    {
        # if the account was successfully managed
        if ($manageaccount = Invoke-CloudSuiteAPI ServerManage/UpdateAccount -Body (@{ID=$this.ID;User=$this.Username;$this.SourceType=$this.SourceID;IsManaged=$true}|ConvertTo-Json))
        {
            $this.isManaged = $true
            return $true
        }
        return $false
    }# [System.Boolean] ManageAccount()

    [System.Boolean] VerifyPassword()
    {
        Write-Debug ("Starting Password Health Check for {0}" -f $this.Username)
        $result = Invoke-CloudSuiteAPI -APICall ServerManage/CheckAccountHealth -Body (@{"ID"=$this.ID} | ConvertTo-Json)
        $this.Healthy = $result
        Write-Debug ("Password Health: {0}" -f $result)

        # if the VerifyCredentials comes back okay, return true
        if ($result -eq "OK")
        {
            return $true
        }
        else
        {
            return $false
        }
    }# VerifyPassword()

    [System.Boolean] UpdatePassword()
    {
        # if the account was successfully managed
        if ($updatepassword = Invoke-CloudSuiteAPI ServerManage/UpdatePassword -Body (@{ID=$this.ID;Password=$this.Password}|ConvertTo-Json))
        {
            return $true
        }
        return $false
    }# [System.Boolean] ManageAccount()

    [System.Boolean] UpdatePassword($password)
    {
        # if the account was successfully managed
        if ($updatepassword = Invoke-CloudSuiteAPI ServerManage/UpdatePassword -Body (@{ID=$this.ID;Password=$password}|ConvertTo-Json))
        {
            return $true
        }
        return $false
    }# [System.Boolean] ManageAccount()

	getAccountEvents()
	{
		$this.AccountEvents.Clear()

		$events = Query-RedRock -SQLQuery ("SELECT EventType,EventMessage AS Message,ComputerName AS SourceName,AccountName,NormalizedUser AS User,whenOccurred FROM Event Where EventType LIKE 'Cloud.Server.{0}Account%' AND ComputerName = '{1}' AND AccountName = '{2}' AND whenOccurred > Datefunc('now',-365)" -f $this.AccountType, $this.SourceName, $this.Username)

		if ($events.Count -gt 0)
		{
			foreach ($event in $events)
			{
				$obj = New-Object CloudSuiteAccountEvent

				$obj.EventType    = $event.EventType
				$obj.Message      = $event.Message
				$obj.SourceName   = $event.SourceName
				$obj.AccountName  = $event.AccountName
				$obj.User         = $event.user
				$obj.whenOccurred = $event.whenOccurred
				
				$this.AccountEvents.Add($obj) | Out-Null
			}# foreach ($event in $events)
		}# if ($events.Count -gt 0)
	}# getAccountEvents()

	[System.Collections.ArrayList] reviewPermissions()
	{
		$ReviewedPermissions = New-Object System.Collections.ArrayList

		foreach ($rowace in $this.PermissionRowAces)
		{
			$ssperms = ConvertTo-SecretServerPermission -Type Self -Name $this.SSName -RowAce $rowace

			$obj = New-Object PSCustomObject

			$obj | Add-Member -MemberType NoteProperty -Name Type -Value $this.AccountType
			$obj | Add-Member -MemberType NoteProperty -Name Source -Value $this.SourceName
			$obj | Add-Member -MemberType NoteProperty -Name Username -Value $this.Username
			$obj | Add-Member -MemberType NoteProperty -Name isManaged -Value $this.isManaged
			$obj | Add-Member -MemberType NoteProperty -Name Healthy -Value $this.Healthy
			$obj | Add-Member -MemberType NoteProperty -Name LastChange -Value $this.LastChange
			$obj | Add-Member -MemberType NoteProperty -Name LastHealthCheck -Value $this.LastHealthCheck
			$obj | Add-Member -MemberType NoteProperty -Name PrincipalType -Value $rowace.PrincipalType
			$obj | Add-Member -MemberType NoteProperty -Name PrincipalName -Value $rowace.PrincipalName
			$obj | Add-Member -MemberType NoteProperty -Name isInherited -Value $rowace.isInherited
			$obj | Add-Member -MemberType NoteProperty -Name PASPermissions -Value $rowace.CloudSuitePermission.GrantString
			$obj | Add-Member -MemberType NoteProperty -Name SSPermissions -Value $ssperms.Permissions
			$obj | Add-Member -MemberType NoteProperty -Name ID -Value $this.ID
			
			$ReviewedPermissions.Add($obj) | Out-Null
		}# foreach ($rowace in $this.PermissionRowAces)
		return $ReviewedPermissions
	}# [System.Collections.ArrayList] reviewPermissions()

	[System.Boolean]CheckoutPassword()
	{
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
				if ($checkout = Invoke-CloudSuiteAPI -APICall ServerManage/CheckoutPassword -Body (@{ID = $this.ID} | ConvertTo-Json))
				{   
					# set these checkout fields
					$pw = ConvertTo-SecureString -AsPlainText -Force -String $checkout.Password
					$this.Password = $pw | ConvertFrom-SecureString -Key $global:CloudSuiteEncryptedKey
					$this.CheckOutID = $checkout.COID
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
			if ($checkout = Invoke-CloudSuiteAPI -APICall ServerManage/CheckoutPassword -Body (@{ID = $this.ID} | ConvertTo-Json))
			{   
				# set these checkout fields
				$this.Password = $checkout.Password
				$this.CheckOutID = $checkout.COID
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
}# class CloudSuiteAccount