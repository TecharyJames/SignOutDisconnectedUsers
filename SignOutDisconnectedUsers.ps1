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

# Gets the DC then querys for all group members, saves them as an array list
$dc = (Get-ADDomainController).name
$group1Name = ""
[System.Collections.ArrayList]$administratorsArray = (get-adgroupmember -server $dc -Identity $groupName).name

# Loops through disconnected users, if they exist in the administrators group does NOT add them to the new disconnected users array // tried remove from current array but it didn't work very well
[System.Collections.ArrayList]$disconnectedUsers = @()
foreach ($user in $disconnectedusersarray)
    {

        if($administratorsarray -notcontains $user.username)
            {

                $disconnectedUsers = $DisconnectedUsers += $user

            }
    }


# Loops through each unified sesssion ID and disconnects it
foreach ($Session in $DisconnectedUsers.ID)
    {

        invoke-rduserlogoff -UnifiedSessionID $Session

    }