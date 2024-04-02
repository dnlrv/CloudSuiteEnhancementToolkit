# class to hold Accounts
class CloudSuiteAccount
{
    [System.String]$AccountType
    [System.String]$ComputerClass
	[System.String]$CredentialType
	[System.String]$CredentialId
	[System.String]$CredentialName
    [System.String]$SourceName
    [System.String]$SourceType
    [System.String]$SourceID
	[System.String]$SourceHealthStatus
	[System.DateTime]$SourceLastHealthCheck
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
	[System.String]$SSSecretTemplate
    [System.String]$CheckOutID
	[System.String]$DatabaseClass
	[System.String]$DatabasePort
	[System.String]$DatabaseServiceName
	[System.Boolean]$DatabaseSSLEnabled
	[PSCustomObject]$PasswordProfile
	[System.Collections.ArrayList]$AccountEvents = @{}
	[System.Collections.ArrayList]$PolicyOptions = @{}

    CloudSuiteAccount() {}

    CloudSuiteAccount($account, [System.String]$t)
    {
       
        $this.AccountType = $t
		$this.CredentialType = $account.CredentialType
		$this.CredentialId = $account.CredentialId
        $this.ComputerClass = $account.ComputerClass
        $this.SourceName = $account.Name

		# getting the SSH key name if SSHKey is used
		if ($this.CredentialType -eq "SshKey")
		{
			$sshkeyquery = Query-RedRock -SQLQuery ("SELECT Name FROM SSHKeys WHERE ID = '{0}'" -f $this.CredentialId) | Select-Object -ExpandProperty Name
			$this.CredentialName = $sshkeyquery
		}# if ($this.CredentialType -eq "SshKey")

		# setting the Secret Server Template (if possible)
		if ($this.ComputerClass -eq "Windows")
		{
			$this.SSSecretTemplate = "WindowsAccount"
		}

		if ($this.AccountType -eq "Domain")
		{
			$this.SSSecretTemplate = "ActiveDirectory"
		}

		if ($this.AccountType -eq "Local" -and $this.ComputerClass -eq "Unix" -and $this.CredentialType -eq "Password")
		{
			$this.SSSecretTemplate = "UnixAccountSSH"
		}

		# tablename for source parent information
		[System.String]$sourcetable = $null

        # the tenant holds the source object's ID in different columns
        Switch ($this.AccountType)
        {
            "Database" { $this.SourceID = $account.DatabaseID; $this.SourceType = "DatabaseId"; $sourcetable = "VaultDatabase"; break }
            "Domain"   { $this.SourceID = $account.DomainID; $this.SourceType = "DomainId"; $sourcetable = "VaultDomain"; break }
            "Local"    { $this.SourceID = $account.Host; $this.SourceType = "Host"; $sourcetable = "Server"; break }
            "Cloud"    { $this.SourceID = $account.CloudProviderID; $this.SourceType = "CloudProviderId"; break }
        }

		# getting and adding parent reachability information
		if ($sourcetable -ne $null)
		{
			$parentstatus = Query-RedRock -SQLQuery ("SELECT HealthStatus,LastHealthCheck FROM {0} WHERE ID = '{1}'" -f $sourcetable, $this.SourceID)

			$this.SourceHealthStatus = $parentstatus.HealthStatus
			$this.SourceLastHealthCheck = $parentstatus.LastHealthCheck
		}# if ($sourcetable -ne $null)

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

		# extra bits for Database accounts
		if ($this.AccountType -eq "Database")
		{
			$databasequery = Query-RedRock -SQLQuery ("SELECT DatabaseClass,Port,ServiceName,SslEnabled FROM VaultDatabase WHERE ID = '{0}'" -f $this.SourceID)

			$this.DatabaseClass       = $databasequery.DatabaseClass
			$this.DatabasePort        = $databasequery.Port
			$this.DatabaseServiceName = $databasequery.ServiceName
			$this.DatabaseSSLEnabled  = $databasequery.SslEnabled
		}# if ($this.AccountType -eq "Database")
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

	getPasswordProfile()
	{
		# clearing out previous entries
		$this.PasswordProfile = $null
		$sourcetable = $null

		# the tenant holds the source object's ID in different columns
        Switch ($this.AccountType)
        {
            "Database" { $sourcetable = "VaultDatabase"; break }
            "Domain"   { $sourcetable = "VaultDomain"; break }
            "Local"    { $sourcetable = "Server"; break }
			default    { break }
        }# Switch ($this.AccountType)

		# querying for the password profile ID from the source table
		if ($passwordprofilequery = Query-RedRock -SQLQuery ("SELECT PasswordProfileID FROM {0} WHERE ID = '{1}'" -f $sourcetable, $this.SourceID) | Select-Object -ExpandProperty PasswordProfileID)
		{
			# hitting the relevant endpoint for the password profile get
			$profiles = Invoke-CloudSuiteAPI -APICall ServerManage/GetPasswordProfiles -Body (@{ProfileTypes="All";RRFormat=$true} | ConvertTo-Json)

			# filtering down to the relevant profile for the source
			$thispasswordprofile = $profiles.Results.Row | Where-Object {$_.ID -eq $passwordprofilequery.Trim()}

			# creating the new object and setting it as a property
			$this.PasswordProfile = New-Object CloudSuitePasswordProfile -ArgumentList ($thispasswordprofile)
		}
		else
		{
			$this.PasswordProfile = "Default"
		}
	}# getPasswordProfile()

	getPolicyOptions()
	{
		$this.PolicyOptions.Clear()

		$getpolicyoptions = Get-CloudSuitePolicyOptions -EntityId $this.ID -TableName VaultAccount

		$this.PolicyOptions.AddRange(@($getpolicyoptions)) | Out-Null
	}# getPolicyOptions()

	[System.Collections.ArrayList] reviewPermissions()
	{
		$ReviewedPermissions = New-Object System.Collections.ArrayList

		foreach ($rowace in $this.PermissionRowAces)
		{
			$ssperms = ConvertTo-SecretServerPermission -Type Self -Name $this.SSName -RowAce $rowace

			$lastEvent = New-Object PSCustomObject

			$lastEvent | Add-Member -MemberType NoteProperty -Name whenOccurred -Value $null
			$lastEvent | Add-Member -MemberType NoteProperty -Name Message -Value $null

			$eventcheck = Query-RedRock -SQLQuery ("SELECT EventMessage AS Message,whenOccurred FROM Event WHERE EventType LIKE 'Cloud.Server.{0}Account%' AND ComputerName = '{1}' AND AccountName = '{2}' AND whenOccurred > Datefunc('now',-500)" -f $this.AccountType, $this.SourceName, $this.Username)

			# if there are more than 0 events
			if (($eventcheck | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
			{
				# set lastEvent to the most recent one
				$lastEvent = $eventcheck | Sort-Object whenOccurred -Descending | Select-Object -First 1
			}

			$obj = New-Object PSCustomObject

			$obj | Add-Member -MemberType NoteProperty -Name Type -Value $this.AccountType
			$obj | Add-Member -MemberType NoteProperty -Name SourceName -Value $this.SourceName
			$obj | Add-Member -MemberType NoteProperty -Name SourceHealthStatus -Value $this.SourceHealthStatus
			$obj | Add-Member -MemberType NoteProperty -Name SourceLastHealthCheck -Value $this.SourceLastHealthCheck
			$obj | Add-Member -MemberType NoteProperty -Name CredentialType -Value $this.CredentialType
			$obj | Add-Member -MemberType NoteProperty -Name CredentialName -Value $this.CredentialName
			$obj | Add-Member -MemberType NoteProperty -Name SourceDatabaseClass -Value $this.DatabaseClass
			$obj | Add-Member -MemberType NoteProperty -Name SourceDatabasePort -Value $this.DatabasePort
			$obj | Add-Member -MemberType NoteProperty -Name SourceDatabaseServiceName -Value $this.DatabaseServiceName
			$obj | Add-Member -MemberType NoteProperty -Name SourceDatabaseSSLEnabled -Value $this.DatabaseSSLEnabled
			$obj | Add-Member -MemberType NoteProperty -Name Username -Value $this.Username
			$obj | Add-Member -MemberType NoteProperty -Name isManaged -Value $this.isManaged
			$obj | Add-Member -MemberType NoteProperty -Name Healthy -Value $this.Healthy
			$obj | Add-Member -MemberType NoteProperty -Name LastChange -Value $this.LastChange
			$obj | Add-Member -MemberType NoteProperty -Name LastHealthCheck -Value $this.LastHealthCheck
			$obj | Add-Member -MemberType NoteProperty -Name PrincipalType -Value $rowace.PrincipalType
			$obj | Add-Member -MemberType NoteProperty -Name PrincipalName -Value $rowace.PrincipalName
			$obj | Add-Member -MemberType NoteProperty -Name isInherited -Value $rowace.isInherited
			$obj | Add-Member -MemberType NoteProperty -Name InheritedFrom -Value $rowace.InheritedFrom
			$obj | Add-Member -MemberType NoteProperty -Name PASPermissions -Value $rowace.CloudSuitePermission.GrantString
			$obj | Add-Member -MemberType NoteProperty -Name SSPermissions -Value $ssperms.Permissions
			$obj | Add-Member -MemberType NoteProperty -Name LastEventTime -Value $lastEvent.whenOccurred
			$obj | Add-Member -MemberType NoteProperty -Name LastEventMessage -Value $lastEvent.Message
			$obj | Add-Member -MemberType NoteProperty -Name ID -Value $this.ID
			$obj | Add-Member -MemberType NoteProperty -Name CredentialId -Value $this.CredentialId
			
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

	[PSCustomObject]exportToSSCCSV()
	{
		$output = $null

		switch ($this.SSSecretTemplate)
		{
			"ActiveDirectory"
			{
				$output = $this | Select-Object @{label="Secret Name";Expression={$this.SSName}},`
									  @{label="Domain";Expression={$this.SourceName}},`
									  @{label="Username";Expression={$this.Username}},`
									  @{label="Password";Expression={$this.Password}},`
									  @{label="Notes";Expression={$this.Description}}
				break
			}
			"WindowsAccount"
			{
				$output = $this | Select-Object @{label="Secret Name";Expression={$this.SSName}},`
									  @{label="Machine";Expression={$this.SourceName}},`
									  @{label="Username";Expression={$this.Username}},`
									  @{label="Password";Expression={$this.Password}},`
									  @{label="Notes";Expression={$this.Description}}
			}
			"UnixAccountSSH"
			{
				$output = $this | Select-Object @{label="Secret Name";Expression={$this.SSName}},`
									  @{label="Machine";Expression={$this.SourceName}},`
									  @{label="Username";Expression={$this.Username}},`
									  @{label="Password";Expression={$this.Password}},`
									  @{label="Notes";Expression={$this.Description}}
			}
			default { break }
		}# switch ($this.SSSecretTemplate)

		return $output
	}# [PSCustomObject]exportToSSCCSV()

	[PSCustomObject]exportToSSCCSV([System.String]$folderpath)
	{
		$output = $null

		switch ($this.SSSecretTemplate)
		{
			"ActiveDirectory"
			{
				$output = $this | Select-Object @{label="Secret Name";Expression={$this.SSName}},`
									  @{label="Domain";Expression={$this.SourceName}},`
									  @{label="Username";Expression={$this.Username}},`
									  @{label="Password";Expression={$this.Password}},`
									  @{label="Notes";Expression={$this.Description}},`
									  @{label="Folder Name";Expression={$folderpath}}
				break
			}
			"WindowsAccount"
			{
				$output = $this | Select-Object @{label="Secret Name";Expression={$this.SSName}},`
									  @{label="Machine";Expression={$this.SourceName}},`
									  @{label="Username";Expression={$this.Username}},`
									  @{label="Password";Expression={$this.Password}},`
									  @{label="Notes";Expression={$this.Description}},`
									  @{label="Folder Name";Expression={$folderpath}}
				break
			}
			"UnixAccountSSH"
			{
				$output = $this | Select-Object @{label="Secret Name";Expression={$this.SSName}},`
									  @{label="Machine";Expression={$this.SourceName}},`
									  @{label="Username";Expression={$this.Username}},`
									  @{label="Password";Expression={$this.Password}},`
									  @{label="Notes";Expression={$this.Description}},`
									  @{label="Folder Name";Expression={$folderpath}}
				break
			}
			default { break }
		}# switch ($this.SSSecretTemplate)

		return $output
	}# [PSCustomObject]exportToSSCCSV([System.String]$folderpath)
}# class CloudSuiteAccount