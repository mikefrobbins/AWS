#Requires -Version 3.0 -Modules AWSPowerShell
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

    $AWSVersion = (Get-Module -Name AWSPowerShell).Version.Major

    if ($AWSVersion -lt 3) {
        $gateway = Get-SGGateway | Where-Object GatewayARN -Like "*$GatewayName"
        $Name = $gateway.GatewayARN -replace '^.*/'
    }
    elseif ($AWSVersion -ge 3) {
        $gateway = Get-SGGateway | Where-Object GatewayName -eq $GatewayName
        $Name = $gateway.GatewayName
    }   
    
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
                GatewayName = $Name
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