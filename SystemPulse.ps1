$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-Module "$ProjectRoot\modules\Graphs.psm1" -Force
Import-Module "$ProjectRoot\modules\Nvidia.psm1" -Force
Import-Module "$ProjectRoot\modules\Metrics.psm1" -Force
Import-Module "$ProjectRoot\modules\Rendering.psm1" -Force

$PreviousNetwork = Get-NetworkCounters
$PreviousTime = Get-Date

$CpuHistory    = New-Object System.Collections.ArrayList
$MemoryHistory = New-Object System.Collections.ArrayList
$GpuHistory    = New-Object System.Collections.ArrayList
$DiskHistory   = New-Object System.Collections.ArrayList

while ($true) {

    $Overview = Get-SystemOverview

    Add-HistoryPoint `
        -History $CpuHistory `
        -Value $Overview.CpuPercent `
        -MaxPoints 8

    Add-HistoryPoint `
        -History $MemoryHistory `
        -Value $Overview.MemoryPercent `
        -MaxPoints 8

    $GpuValue = 0

    if ($null -ne $Overview.GpuPercent) {
        $GpuValue = $Overview.GpuPercent
    }

    Add-HistoryPoint `
        -History $GpuHistory `
        -Value $GpuValue `
        -MaxPoints 8

    $DiskValue = 0

    if ($null -ne $Overview.DiskBusy) {
        $DiskValue = $Overview.DiskBusy
    }

    Add-HistoryPoint `
        -History $DiskHistory `
        -Value $DiskValue `
        -MaxPoints 8

    $Overview | Add-Member `
        -NotePropertyName CpuHistory `
        -NotePropertyValue (
            ConvertTo-HistoryGraph $CpuHistory
        ) `
        -Force

    $Overview | Add-Member `
        -NotePropertyName MemoryHistory `
        -NotePropertyValue (
            ConvertTo-HistoryGraph $MemoryHistory
        ) `
        -Force

    $Overview | Add-Member `
        -NotePropertyName GpuHistory `
        -NotePropertyValue (
            ConvertTo-HistoryGraph $GpuHistory
        ) `
        -Force

    $Overview | Add-Member `
        -NotePropertyName DiskHistory `
        -NotePropertyValue (
            ConvertTo-HistoryGraph $DiskHistory
        ) `
        -Force

    $CurrentNetwork = Get-NetworkCounters
    $CurrentTime = Get-Date

    $ElapsedSeconds =
        ($CurrentTime - $PreviousTime).TotalSeconds

    if ($ElapsedSeconds -le 0) {
        $ElapsedSeconds = 1
    }

    $DownloadRate = 0
    $UploadRate = 0

    if ($CurrentNetwork -and $PreviousNetwork) {

        $DownloadRate =
            ($CurrentNetwork.ReceivedBytes -
             $PreviousNetwork.ReceivedBytes) /
            $ElapsedSeconds

        $UploadRate =
            ($CurrentNetwork.SentBytes -
             $PreviousNetwork.SentBytes) /
            $ElapsedSeconds

        if ($DownloadRate -lt 0) {
            $DownloadRate = 0
        }

        if ($UploadRate -lt 0) {
            $UploadRate = 0
        }
    }

    $Overview | Add-Member `
        -NotePropertyName DownloadRate `
        -NotePropertyValue $DownloadRate `
        -Force

    $Overview | Add-Member `
        -NotePropertyName UploadRate `
        -NotePropertyValue $UploadRate `
        -Force

    Show-SystemPulseOverview -Overview $Overview

    $PreviousNetwork = $CurrentNetwork
    $PreviousTime = $CurrentTime

    Start-Sleep -Seconds 1
}