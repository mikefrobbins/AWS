#Requires -Version 3.0
#Requires -Modules AWSPowerShell
function Get-MrAWSSGSnapShot {

<#
.SYNOPSIS
    Returns a list of snapshots for the specified AWS storage gateway.
 
.DESCRIPTION
    Get-MrAWSSGSnapShot is a PowerShell function that returns a list of
    snapshots for the specified AWS storage gateway. In addition to specifying
    the name of the storage gateway, snapshots can be filtered by the number of
    days and the status of the snapshot. 
 
.PARAMETER GatewayName
    Name of the storage gateway.
 
.PARAMETER Days
    Only show snapshots older than this many days specified as a positive integer.
 
.PARAMETER Status
    Only show snapshots with this specified status. The default value is completed.
 
.EXAMPLE
    Get-MrAWSSGSnapShot -GatewayName 'Server01'
 
.EXAMPLE
    Get-MrAWSSGSnapShot -GatewayName 'Server01' -Days 14
 
.EXAMPLE
    Get-MrAWSSGSnapShot -GatewayName 'Server01' -Days 14 -Status 'error'
 
.INPUTS
    None
 
.OUTPUTS
    Mr.AWS.Snapshot
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$GatewayName,
        
        [int]$Days,
        
        [ValidateSet('pending', 'completed', 'error')]
        [string]$Status = 'completed'
    )

    $gateway = Get-SGGateway | Where-Object GatewayARN -Like "*$GatewayName"
    $volumes = (($gateway | Get-SGVolume).VolumeARN -replace '^.*/').ToLower()
    $cutoff = (Get-Date).AddDays(-$Days)

    foreach ($volume in $volumes) {
        
        $filter1 = New-Object Amazon.EC2.Model.Filter
        $filter1.Name = 'volume-id'
        $filter1.Value.Add($volume)

        $filter2 = New-Object Amazon.EC2.Model.Filter
        $filter2.Name = 'status'
        $filter2.Value.Add($status)

        $snapshots = Get-EC2Snapshot -Filter $filter1, $filter2 |
                     Where-Object StartTime -lt $cutoff

        foreach ($snapshot in $snapshots) {

            $CustomObject = [PSCustomObject]@{
                GatewayName = $gateway.GatewayARN -replace '^.*/'
                VolumeId = $snapshot.VolumeId
                SnapshotId = $snapshot.SnapshotId
                StartTime = $snapshot.StartTime
                State = $snapshot.State
                VolumeSize = $snapshot.VolumeSize               
            }

            $CustomObject.PSTypeNames.Insert(0,'Mr.AWS.Snapshot')
    
            Write-Output $CustomObject
        }
        
    }
}

#Requires -Version 3.0
#Requires -Modules AWSPowerShell
function Remove-MrAWSSGSnapShot {

<#
.SYNOPSIS
    Removes snapshots from the specified AWS storage gateway.
 
.DESCRIPTION
    Remove-MrAWSSGSnapShot is a PowerShell function that removes snapshots from
    the specified AWS storage gateway. By default it removes snapshots that are
    older than 14 days that have a status of completed.
 
.PARAMETER GatewayName
    Name of the storage gateway.
 
.PARAMETER Days
    Remove snapshots older than this many days specified as a positive integer.
 
.PARAMETER Status
    Only remove snapshots with this specified status. The default value is completed.
 
.EXAMPLE
    Remove-MrAWSSGSnapShot -GatewayName 'Server01'
 
.EXAMPLE
    Remove-MrAWSSGSnapShot -GatewayName 'Server01' -Days 30
 
.EXAMPLE
    Remove-MrAWSSGSnapShot -GatewayName 'Server01' -Days 7 -Status 'error'
 
.INPUTS
    None
 
.OUTPUTS
    None
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$GatewayName,
        
        [ValidateNotNullOrEmpty()]
        [int]$Days = 14 ,
        
        [ValidateSet('pending', 'completed', 'error')]
        [string]$Status = 'completed'
    )

    $volumes = ((Get-SGGateway |
                 Where-Object GatewayARN -Like "*$GatewayName" |
                 Get-SGVolume).VolumeARN -replace '^.*/').ToLower()

    $cutoff = (Get-Date).AddDays(-$Days)
    
    $Params = @{}

    If ((-not($PSBoundParameters['Confirm'])) -and (-not($PSBoundParameters['WhatIf']))) {
        $Params.force = $true
    }

    foreach ($volumeID in $volumes) {
        $filter1 = New-Object Amazon.EC2.Model.Filter
        $filter1.Name = 'volume-id'
        $filter1.Value.Add($volumeID)

        $filter2 = New-Object Amazon.EC2.Model.Filter
        $filter2.Name = 'status'
        $filter2.Value.Add($status)

        Get-EC2Snapshot -Filter $filter1, $filter2 |
        Where-Object StartTime -lt $cutoff |
        Remove-EC2Snapshot @Params

    }
}