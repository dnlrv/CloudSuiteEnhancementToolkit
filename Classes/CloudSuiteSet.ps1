
# class to hold Sets
class CloudSuiteSet
{
    [System.String]$SetType
    [System.String]$ObjectType
    [System.String]$Name
    [System.String]$ID
    [System.String]$Description
    [System.DateTime]$whenCreated
    [System.String]$ParentPath
    [PSCustomObject[]]$PermissionRowAces             # permissions of the Set object itself
    [PSCustomObject[]]$MemberPermissionRowAces       # permissions of the members for this Set object
    [System.Collections.ArrayList]$MembersUuid = @{} # the Uuids of the members
    [System.Collections.ArrayList]$SetMembers  = @{} # the members of this set
    [System.String]$PotentialOwner                   # a guess as to who possibly owns this set
	[System.Collections.ArrayList]$SetEvents = @{}

    CloudSuiteSet() {}

    CloudSuiteSet($set)
    {
        $this.SetType = $set.CollectionType
        $this.ObjectType = $set.ObjectType
        $this.Name = $set.Name
        $this.ID = $set.ID
        $this.Description = $set.Description
        $this.ParentPath = $set.ParentPath

        if ($set.whenCreated -ne $null)
        {
            $this.whenCreated = $set.whenCreated
        }

        # getting the RowAces for this Set
        $this.PermissionRowAces = Get-CloudSuiteRowAce -Type $this.SetType -Uuid $this.ID

        # if this isn't a Dynamic Set
        if ($this.SetType -ne "SqlDynamic")
        {
            # getting the RowAces for the member permissions
        $this.MemberPermissionRowAces = Get-CloudSuiteCollectionRowAce -Type $this.ObjectType -Uuid $this.ID
        }
    }# CloudSuiteSet($set)

    getMembers()
    {
        # nulling out both member fields
        $this.MembersUuid.Clear()
        $this.SetMembers.Clear()

        # getting members
        [PSObject]$m = $null

        # a little tinkering because Secret Folders ('Phantom') need a different endpoint to get members
        Switch ($this.SetType)
        {
            "Phantom" # if this SetType is a Secret Folder
            { 
                # get the members and reformat the data a bit so it matches Collection/GetMembers
                $m = Invoke-CloudSuiteAPI -APICall ServerManage/GetSecretsAndFolders -Body (@{Parent=$this.ID} | ConvertTo-Json)
                $m = $m.Results.Entities
                $m | Add-Member -Type NoteProperty -Name Table -Value DataVault
                break
            }# "Phantom" # if this SetType is a Secret Folder
            "ManualBucket" # if this SetType is a Manual Set
            {
                $m = Invoke-CloudSuiteAPI -APICall Collection/GetMembers -Body (@{ID = $this.ID} | ConvertTo-Json)
            }
            default        { break }
        }# Switch ($this.SetType)

        # getting the set members
        if ($m -ne $null)
        {
            # for each item in the query
            foreach ($i in $m)
            {
                $obj = $null
                
                # getting the object based on the Uuid
                Switch ($i.Table)
                {
                    "DataVault"    {$obj = Query-RedRock -SQLQuery ("SELECT ID AS Uuid,SecretName AS Name FROM DataVault WHERE ID = '{0}'" -f $i.Key); break }
                    "VaultAccount" {$obj = Query-RedRock -SQLQuery ("SELECT ID AS Uuid,(Name || '\' || User) AS Name FROM VaultAccount WHERE ID = '{0}'" -f $i.Key); break }
                    "Server"       {$obj = Query-RedRock -SQLQuery ("SELECT ID AS Uuid,Name FROM Server WHERE ID = '{0}'" -f $i.Key); break }
                }

                # new SetMember
                $tmp = New-Object SetMember -ARgumentList ($obj.Name,$obj.Uuid)

                # adding the Uuids to the Members property
                $this.MembersUuid.Add(($i.Key)) | Out-Null

                # adding the SetMembers to the SetMembers property
                $this.SetMembers.Add(($tmp))    | Out-Null
            }# foreach ($i in $m)
        }# if ($m.Count -gt 0)
    }# getMembers()

    # helps determine who might own this set
    determineOwner()
    {
        # get all RowAces where the PrincipalType is User and has all permissions on this Set object
        $owner = $this.PermissionRowAces | Where-Object {$_.PrincipalType -eq "User" -and ($_.CloudSuitePermission.GrantInt -eq 253 -or $_.CloudSuitePermission.GrantInt -eq 65789)}

        Switch ($owner.Count)
        {
            1       { $this.PotentialOwner = $owner.PrincipalName ; break }
            0       { $this.PotentialOwner = "No owners found"    ; break }
            default { $this.PotentialOwner = "Multiple potential owners found" ; break }
        }# Switch ($owner.Count)
    }# determineOwner()

    [PSCustomObject]getCloudSuiteObjects()
    {
        $CloudSuiteObjects = New-Object System.Collections.ArrayList

        [System.String]$command = $null

        Switch ($this.ObjectType)
        {
            "DataVault"    { $command = 'Get-CloudSuiteSecret'; break }
            "Server"       { $command = 'Get-CloudSuiteSystem'; break }
            "VaultAccount" { $command = 'Get-CloudSuiteAccount'; break }
            default        { Write-Host "This set type not supported yet."; return $false ; break }
        }# Switch ($this.ObjectType)

		
		if ($this.ObjectType -eq "VaultAccount")
		{
			Invoke-Expression -Command ('[void]$CloudSuiteObjects.AddRange(@(Get-CloudSuiteAccount -Uuid {0}))' -f (($this.MembersUuid -replace '^(.*)$',"'`$1'") -join ","))
		}
		else
		{
			foreach ($id in $this.MembersUuid)
			{
			    Invoke-Expression -Command ('[void]$CloudSuiteObjects.Add(({0} -Uuid {1}))' -f $command, $id)
			}
		}

        return $CloudSuiteObjects
    }# [PSCustomObject]getCloudSuiteObjects()

	getSetEvents()
	{
		$this.SetEvents.Clear()

		$events = Query-RedRock -SQLQuery ("SELECT EventType,EventMessage AS Message,NormalizedUser AS User,whenOccurred FROM Event Where EntityUuid = '{0}' AND whenOccurred > Datefunc('now',-500)" -f $this.ID)

		# if there is more than 0 events
		if (($events | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
		{
			foreach ($event in $events)
			{
				$obj = New-Object CloudSuiteSetEvent

				$obj.EventType    = $event.EventType
				$obj.Message      = $event.Message
				$obj.User         = $event.User
				$obj.whenOccurred = $event.whenOccurred
				
				$this.SetEvents.Add($obj) | Out-Null
			}# foreach ($event in $events)
		}# if ($events.Count -gt 0)
	}# getSetEvents()

	getSetEvents([System.Int32]$days)
	{
		$this.SetEvents.Clear()

		$events = Query-RedRock -SQLQuery ("SELECT EventType,EventMessage AS Message,NormalizedUser AS User,whenOccurred FROM Event Where EntityUuid = '{0}' AND whenOccurred > Datefunc('now',{1})" -f $this.ID, $days)

		# if there is more than 0 events
		if (($events | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
		{
			foreach ($event in $events)
			{
				$obj = New-Object CloudSuiteSetEvent

				$obj.EventType    = $event.EventType
				$obj.Message      = $event.Message
				$obj.User         = $event.User
				$obj.whenOccurred = $event.whenOccurred
				
				$this.SetEvents.Add($obj) | Out-Null
			}# foreach ($event in $events)
		}# if ($events.Count -gt 0)
	}# getSetEvents()

	[System.Collections.ArrayList] reviewPermissions()
	{
		$ReviewedPermissions = New-Object System.Collections.ArrayList

		# going through Set permissions first
		foreach ($rowace in $this.PermissionRowAces)
		{
			$ssperms = ConvertTo-SecretServerPermission -Type Set -Name $this.Name -RowAce $rowace

			$obj = New-Object PSCustomObject

			$obj | Add-Member -MemberType NoteProperty -Name OnObject -Value "Set"
			$obj | Add-Member -MemberType NoteProperty -Name ObjectType -Value $this.ObjectType
			$obj | Add-Member -MemberType NoteProperty -Name ObjectName -Value $this.Name
			$obj | Add-Member -MemberType NoteProperty -Name PrincipalType -Value $rowace.PrincipalType
			$obj | Add-Member -MemberType NoteProperty -Name PrincipalName -Value $rowace.PrincipalName
			$obj | Add-Member -MemberType NoteProperty -Name isInherited -Value $rowace.isInherited
			$obj | Add-Member -MemberType NoteProperty -Name InheritedFrom -Value $rowace.InheritedFrom
			$obj | Add-Member -MemberType NoteProperty -Name PASPermissions -Value $rowace.CloudSuitePermission.GrantString
			$obj | Add-Member -MemberType NoteProperty -Name SSPermissions -Value $ssperms.Permissions
			$obj | Add-Member -MemberType NoteProperty -Name SetID -Value $this.ID

			$ReviewedPermissions.Add($obj) | Out-Null
		}# foreach ($rowace in $this.PermissionRowAces)

		# then go through Member permissions next
		foreach ($memberrowace in $this.MemberPermissionRowAces)
		{
			$ssperms = ConvertTo-SecretServerPermission -Type SetMember -Name $this.Name -RowAce $memberrowace

			$obj = New-Object PSCustomObject

			$obj | Add-Member -MemberType NoteProperty -Name OnObject -Value "Member"
			$obj | Add-Member -MemberType NoteProperty -Name ObjectType -Value $this.ObjectType
			$obj | Add-Member -MemberType NoteProperty -Name ObjectName -Value $this.Name
			$obj | Add-Member -MemberType NoteProperty -Name PrincipalType -Value $memberrowace.PrincipalType
			$obj | Add-Member -MemberType NoteProperty -Name PrincipalName -Value $memberrowace.PrincipalName
			$obj | Add-Member -MemberType NoteProperty -Name isInherited -Value $memberrowace.isInherited
			$obj | Add-Member -MemberType NoteProperty -Name InheritedFrom -Value $memberrowace.InheritedFrom
			$obj | Add-Member -MemberType NoteProperty -Name PASPermissions -Value $memberrowace.CloudSuitePermission.GrantString
			$obj | Add-Member -MemberType NoteProperty -Name SSPermissions -Value $ssperms.Permissions
			$obj | Add-Member -MemberType NoteProperty -Name SetID -Value $this.ID

			$ReviewedPermissions.Add($obj) | Out-Null
		}# foreach ($memberrowace in $this.MemberPermissionRowAces)
		return $ReviewedPermissions
	}# [System.Collections.ArrayList] reviewPermissions()
}# class CloudSuiteSet