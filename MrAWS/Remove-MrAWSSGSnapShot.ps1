#Requires -Version 3.0 -Modules AWSPowerShell
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

    $AWSVersion = (Get-Module -Name AWSPowerShell).Version.Major

    if ($AWSVersion -lt 3) {
        $gateway = Get-SGGateway | Where-Object GatewayARN -Like "*$GatewayName"
    }
    elseif ($AWSVersion -ge 3) {
        $gateway = Get-SGGateway | Where-Object GatewayName -eq $GatewayName
    } 

    $volumes = (($gateway | Get-SGVolume).VolumeARN -replace '^.*/').ToLower()
    $cutoff = (Get-Date).AddDays(-$Days)
    $Params = @{}

    If ((-not($PSBoundParameters['Confirm'])) -and (-not($PSBoundParameters['WhatIf']))) {
        $Params.force = $true
    }

    foreach ($volume in $volumes) {
        $filter1 = New-Object Amazon.EC2.Model.Filter
        $filter1.Name = 'volume-id'
        $filter1.Value.Add($volume)

        $filter2 = New-Object Amazon.EC2.Model.Filter
        $filter2.Name = 'status'
        $filter2.Value.Add($status)

        Get-EC2Snapshot -Filter $filter1, $filter2 |
        Where-Object StartTime -lt $cutoff |
        Remove-EC2Snapshot @Params

    }
}