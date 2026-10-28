Import-Module "$PSScriptRoot\Nvidia.psm1" -Force

function Get-CpuUsage {

    try {
        $cpu = Get-CimInstance `
            Win32_PerfFormattedData_PerfOS_Processor |
            Where-Object {
                $_.Name -eq "_Total"
            } |
            Select-Object -First 1

        if ($cpu) {
            return [double]$cpu.PercentProcessorTime
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-MemoryInfo {

    try {

        $os = Get-CimInstance Win32_OperatingSystem

        $total = [double]$os.TotalVisibleMemorySize * 1KB
        $free  = [double]$os.FreePhysicalMemory * 1KB

        $used = $total - $free

        return [pscustomobject]@{
            Total   = $total
            Used    = $used
            Free    = $free
            Percent = [math]::Round(
                ($used / $total) * 100,
                1
            )
        }
    }
    catch {
        return $null
    }
}

function Get-SystemOverview {

    $cpu = Get-CpuUsage
    $memory = Get-MemoryInfo
    $gpu = Get-NvidiaInfo
    $uptime = Get-SystemUptime
    $disk = Get-DiskActivity

    [pscustomobject]@{
        CpuPercent    = $cpu

        MemoryPercent = $memory.Percent
        MemoryUsedGB  = [math]::Round(
            $memory.Used / 1GB,
            1
        )

        MemoryTotalGB = [math]::Round(
            $memory.Total / 1GB,
            1
        )

        GpuName       = if($gpu){$gpu.Name}else{"Unavailable"}
        GpuPercent    = if($gpu){$gpu.Load}else{$null}
        GpuTemp       = if($gpu){$gpu.Temp}else{$null}

        GpuVramUsedGB =
            if($gpu){
                [math]::Round($gpu.VramUsed / 1024,1)
            }
            else{
                $null
            }

        GpuVramTotalGB =
            if($gpu){
                [math]::Round($gpu.VramTotal / 1024,1)
            }
            else{
                $null
            }
Uptime = $uptime

DiskBusy =
    if($disk){
        $disk.PercentBusy
    }
    else{
        $null
    }

DiskRead =
    if($disk){
        $disk.ReadBytesPerSec
    }
    else{
        $null
    }

DiskWrite =
    if($disk){
        $disk.WriteBytesPerSec
    }
    else{
        $null
    }
    }
}

function Get-NetworkCounters {

    try {

        $stats = Get-NetAdapterStatistics |
            Where-Object {
                $_.ReceivedBytes -ge 0
            }

        [pscustomobject]@{
            ReceivedBytes =
                [double](
                    ($stats |
                        Measure-Object -Property ReceivedBytes -Sum
                    ).Sum
                )

            SentBytes =
                [double](
                    ($stats |
                        Measure-Object -Property SentBytes -Sum
                    ).Sum
                )
        }

    }
    catch {

        return $null

    }
}

function Get-SystemUptime {

    try {

        $os = Get-CimInstance Win32_OperatingSystem

        $bootTime = $os.LastBootUpTime

        $uptime = (Get-Date) - $bootTime

        return $uptime
    }
    catch {

        return $null

    }
}

function Get-DiskActivity {

    try {

        $disk = Get-CimInstance `
            Win32_PerfFormattedData_PerfDisk_LogicalDisk |
            Where-Object {
                $_.Name -eq "_Total"
            } |
            Select-Object -First 1

        if (-not $disk) {
            return $null
        }

        return [pscustomobject]@{
            ReadBytesPerSec  = [double]$disk.DiskReadBytesPersec
            WriteBytesPerSec = [double]$disk.DiskWriteBytesPersec
            PercentBusy      = [double]$disk.PercentDiskTime
        }
    }
    catch {

        return $null

    }
}

Export-ModuleMember -Function `
    Get-CpuUsage, `
    Get-MemoryInfo, `
    Get-SystemOverview, `
    Get-NetworkCounters, `
    Get-SystemUptime, `
    Get-DiskActivity