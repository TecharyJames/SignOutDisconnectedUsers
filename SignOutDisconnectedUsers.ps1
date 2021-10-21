#####################################
## Author: James Tarran // Techary ##
#####################################

# Custom function to convert the cmd "quser" to a powershell manipulatable object
function Get-LoggedInuser {

    $stringOutput = quser /server:$Comp 2>$null

    ForEach ($line in $stringOutput)
    {
        If ($line -match "logon time") 
        {Continue}
        [PSCustomObject]@{
        ComputerName    = $Comp
        Username        = $line.SubString(1, 20).Trim()
        SessionName     = $line.SubString(23, 17).Trim()
        ID             = $line.SubString(42, 2).Trim()
        State           = $line.SubString(46, 6).Trim()
        #Idle           = $line.SubString(54, 9).Trim().Replace('+', '.')
        #LogonTime      = [datetime]$line.SubString(65)
        }
    } 
}

# Gets the needed windows capability to query AD for group members via powershell (not working on servers so commented out)
# Add-WindowsCapability  -online -name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" | Out-Null

# Saves disconnected users to an array list
[System.Collections.ArrayList]$DisconnectedUsersArray = (Get-LoggedInuser | where {$_.state -eq "disc"})

# Gets the DC then querys each group for all members, adds them to an array list
$dc = (Get-ADDomainController).name
$ExcludedGroups = @("<group1>", "<group2>")

[System.Collections.ArrayList]$ExcludedUsers = @()
foreach ($group in $ExcludedGroups)
    {

        $ExcludedUsers = $ExcludedUsers += (get-adgroupmember -server $dc -Identity $group).SAMAccountName

    }

# Loops through disconnected users, if they exist in the excluded users group does NOT add them to the new disconnected users array
[System.Collections.ArrayList]$UsersToDisconnect = @()
foreach ($user in $disconnectedusersarray)
    {

        if($ExcludedUsers -notcontains $user.username)
            {

                $UsersToDisconnect = $UsersToDisconnect += $user

            }
    }


# Loops through each unified sesssion ID and disconnects it
foreach ($Session in $UsersToDisconnect)

    {

        invoke-rduserlogoff -UnifiedSessionID $Session.ID

    }

