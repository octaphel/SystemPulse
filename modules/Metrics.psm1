Import-Module "$PSScriptRoot\Nvidia.psm1" -Force

$script:PreviousProcessSample = @{}
$script:LastProcessSampleTime = Get-Date

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

function Get-TopCpuProcess {

    try {

        $now = Get-Date
        $elapsed =
            ($now - $script:LastProcessSampleTime).TotalSeconds

        if ($elapsed -le 0) {
            return $null
        }

        $processes =
            Get-Process -ErrorAction SilentlyContinue |
            Where-Object {
                $null -ne $_.CPU
            }

        $best = $null
        $highest = 0

        foreach ($proc in $processes) {

            $pid = $proc.Id
            $cpu = [double]$proc.CPU

            if ($script:PreviousProcessSample.ContainsKey($pid)) {

                $delta =
                    $cpu -
                    $script:PreviousProcessSample[$pid]

                if ($delta -ge 0) {

                    $percent =
                        ($delta / $elapsed) /
                        [Environment]::ProcessorCount * 100

                    if ($percent -gt $highest) {

                        $highest = $percent

                        $best = [pscustomobject]@{
                            Name    = $proc.ProcessName
                            Percent = [math]::Round(
                                $percent,
                                1
                            )
                        }
                    }
                }
            }
        }

        $script:PreviousProcessSample = @{}

        foreach ($proc in $processes) {
            $script:PreviousProcessSample[$proc.Id] =
                [double]$proc.CPU
        }

        $script:LastProcessSampleTime = $now

        return $best
    }
    catch {
        return $null
    }
}

function Get-TopMemoryProcess {

    try {

        $process =
            Get-Process -ErrorAction SilentlyContinue |
            Sort-Object WorkingSet64 -Descending |
            Select-Object -First 1

        if (-not $process) {
            return $null
        }

        return [pscustomobject]@{
            Name = $process.ProcessName
            GB   = [math]::Round(
                $process.WorkingSet64 / 1GB,
                2
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

    $topCpu = Get-TopCpuProcess
    $topMemory = Get-TopMemoryProcess

    [pscustomobject]@{

        CpuPercent = $cpu

        MemoryPercent = $memory.Percent

        MemoryUsedGB = [math]::Round(
            $memory.Used / 1GB,
            1
        )

        MemoryTotalGB = [math]::Round(
            $memory.Total / 1GB,
            1
        )

        GpuName =
            if($gpu){
                $gpu.Name
            }
            else{
                "Unavailable"
            }

        GpuPercent =
            if($gpu){
                $gpu.Load
            }
            else{
                $null
            }

        GpuTemp =
            if($gpu){
                $gpu.Temp
            }
            else{
                $null
            }

        GpuVramUsedGB =
            if($gpu){
                [math]::Round(
                    $gpu.VramUsed / 1024,
                    1
                )
            }
            else{
                $null
            }

        GpuVramTotalGB =
            if($gpu){
                [math]::Round(
                    $gpu.VramTotal / 1024,
                    1
                )
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

        TopCpuProcess =
            if($topCpu){
                $topCpu.Name
            }
            else{
                "Sampling..."
            }

        TopCpuPercent =
            if($topCpu){
                $topCpu.Percent
            }
            else{
                $null
            }

        TopMemoryProcess =
            if($topMemory){
                $topMemory.Name
            }
            else{
                "Unavailable"
            }

        TopMemoryGB =
            if($topMemory){
                $topMemory.GB
            }
            else{
                $null
            }
    }
}

function Get-NetworkCounters {

    try {

        $stats =
            Get-NetAdapterStatistics |
            Where-Object {
                $_.ReceivedBytes -ge 0
            }

        [pscustomobject]@{

            ReceivedBytes =
                [double](
                    ($stats |
                        Measure-Object `
                            -Property ReceivedBytes `
                            -Sum
                    ).Sum
                )

            SentBytes =
                [double](
                    ($stats |
                        Measure-Object `
                            -Property SentBytes `
                            -Sum
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

        $os =
            Get-CimInstance Win32_OperatingSystem

        $bootTime =
            $os.LastBootUpTime

        return (
            (Get-Date) - $bootTime
        )
    }
    catch {
        return $null
    }
}

function Get-DiskActivity {

    try {

        $disk =
            Get-CimInstance `
            Win32_PerfFormattedData_PerfDisk_LogicalDisk |
                Select-Object -First 1

        if (-not $disk) {
            return $null
        }

        [pscustomobject]@{

            ReadBytesPerSec =
                [double]$disk.DiskReadBytesPersec

            WriteBytesPerSec =
                [double]$disk.DiskWriteBytesPersec

            PercentBusy =
                [double]$disk.PercentDiskTime
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