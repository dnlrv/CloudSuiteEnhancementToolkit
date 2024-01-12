# CloudSuiteEnhancementToolkit
A variety of functions to make working with Delinea's Cloud Suite even easier

# CloudSuiteEnhancementToolkit
```
$CloudSuiteEnhancementToolkit = ([ScriptBlock]::Create(((Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DelineaPS/CloudSuiteEnhancementToolkit/main/CloudSuiteEnhancementToolkit.ps1').Content))); . $CloudSuiteEnhancementToolkit
```

## CloudSuiteEnhancementToolkit (local)
If you want to run all of this locally, download all the scripts in this repo to a local folder, and run the primary script with the following:

```
. CloudSuiteEnhancementToolkit_local.ps1
```

# How to use

After the above loading snippets are run, you can see the list of cmdlets available within this module within the following snippet:

```
$CloudSuiteEnhancementToolkitScriptBlocks | Where {$_.Type -eq "Function"}
```

All functions have standard PowerShell help files associated with them. So you can use `Get-Help Connect-CloudSuiteTenant` to get the help file for that cmdlet.

First you need to connect to your tenant with `Connect-CloudSuiteTenant`. Here is an example usage

```
Connect-CloudSuiteTenant -Url mytenant.my.centrify.net -User mycloudadmin@domain.com
```

You will be prompted for a password and whatever MFA challenge is associated with that login.

**Known issue:** Federated Users will not work here. Use a Centrify Directory user instead.

## Once Connected

If you get output from the `Connect-CloudSuiteTenant` cmdlet, you're connected and will remain connected for however long your tenant allows you to stay connected. All further cmdlets using this module from this point forward will use your credentials as if you were logged into the GUI tenant.

Some cmdlets have additional methods with the custom class objects they return. For example `Get-CloudSuiteAccount` has additional methods such as `.getAccountEvents()` to obtain all events for this account within the past 365 days. See the help file for each cmdlet for more details.

# Full list of public cmdlets in this module

- Checkout-CloudSuiteAccountPassword
- Connect-CloudSuiteTenant
- Decrypt-CloudSuiteAccountPassword
- Decrypt-CloudSuiteSecretText
- Find-SetMembersInOtherSets
- Get-CloudSuiteAccount
- Get-CloudSuiteAccountEvents
- Get-CloudSuiteObjectHash
- Get-CloudSuiteObjectUuid
- Get-CloudSuitePolicyOptions
- Get-CloudSuitePrincipal
- Get-CloudSuiteRole
- Get-CloudSuiteSecret
- Get-CloudSuiteSecretEvents
- Get-CloudSuiteSet
- Get-CloudSuiteSystem
- Get-CloudSuiteVault
- Invoke-CloudSuiteAPI
- Query-RedRock
- Retrieve-CloudSuiteSecretText
- Search-CloudSuiteDirectory
- Set-CloudSuiteEncryptionKey
- Switch-CloudSuiteTenant