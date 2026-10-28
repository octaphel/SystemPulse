function Format-TransferRate {

    param(
        [double]$BytesPerSecond
    )

    if ($BytesPerSecond -ge 1GB) {
        return ("{0:N2} GB/s" -f ($BytesPerSecond / 1GB))
    }

    if ($BytesPerSecond -ge 1MB) {
        return ("{0:N2} MB/s" -f ($BytesPerSecond / 1MB))
    }

    if ($BytesPerSecond -ge 1KB) {
        return ("{0:N2} KB/s" -f ($BytesPerSecond / 1KB))
    }

    return ("{0:N0} B/s" -f $BytesPerSecond)
}

function Format-Uptime {

    param(
        $Uptime
    )

    if (-not $Uptime) {
        return "Unavailable"
    }

    return (
        "{0}d {1:D2}h {2:D2}m {3:D2}s" -f
        $Uptime.Days,
        $Uptime.Hours,
        $Uptime.Minutes,
        $Uptime.Seconds
    )
}

function Show-SystemPulseOverview {

    param(
        [object]$Overview
    )

    Clear-Host

    $Clock = (Get-Date).ToString("HH:mm:ss")

    $HighestLoad = @(
        $Overview.CpuPercent,
        $Overview.MemoryPercent,
        $Overview.GpuPercent,
        $Overview.DiskBusy
    ) | Where-Object {
        $null -ne $_
    } | Measure-Object -Maximum

    $BorderColor = "Green"

    if ($HighestLoad.Maximum -ge 85) {
        $BorderColor = "Red"
    }
    elseif ($HighestLoad.Maximum -ge 60) {
        $BorderColor = "Yellow"
    }

    $StatusText = "OPTIMAL"
    $StatusColor = "Green"

    if ($HighestLoad.Maximum -ge 95) {

        $StatusText = "CRITICAL"
        $StatusColor = "Red"

    }
    elseif ($HighestLoad.Maximum -ge 85) {

        $StatusText = "STRESSED"
        $StatusColor = "Red"

    }
    elseif ($HighestLoad.Maximum -ge 60) {

        $StatusText = "ELEVATED LOAD"
        $StatusColor = "Yellow"

    }

    Write-Host ""

    Write-Host "=======================================================" `
        -ForegroundColor $BorderColor

    Write-Host "SYSTEM PULSE" `
        -NoNewline `
        -ForegroundColor Green

    Write-Host (" " * 4) `
        -NoNewline

    Write-Host $StatusText `
        -NoNewline `
        -ForegroundColor $StatusColor

    Write-Host (" " * 8) `
        -NoNewline

    Write-Host $Clock `
        -ForegroundColor Yellow

    Write-Host "=======================================================" `
        -ForegroundColor $BorderColor

    Write-Host ""

    Write-Host (
        "Uptime       : {0}" -f
        (Format-Uptime $Overview.Uptime)
    ) -ForegroundColor Gray

    Write-Host ""

    Write-Host "CPU" -ForegroundColor Cyan

    Write-Host (
        "  Usage       : {0} {1:N1}%" -f
        (New-UsageBar $Overview.CpuPercent),
        $Overview.CpuPercent
    )

    Write-Host ""

    Write-Host "MEMORY" -ForegroundColor Cyan

    Write-Host (
        "  Usage       : {0} {1:N1}%" -f
        (New-UsageBar $Overview.MemoryPercent),
        $Overview.MemoryPercent
    )

    Write-Host (
        "  Capacity    : {0:N1} / {1:N1} GB" -f
        $Overview.MemoryUsedGB,
        $Overview.MemoryTotalGB
    )

    Write-Host ""

    Write-Host "GPU" -ForegroundColor Cyan

    if ($null -ne $Overview.GpuPercent) {

        Write-Host (
            "  Usage       : {0} {1:N1}%" -f
            (New-UsageBar $Overview.GpuPercent),
            $Overview.GpuPercent
        )

        Write-Host (
            "  Temp        : {0:N0} C" -f
            $Overview.GpuTemp
        )

        Write-Host (
            "  VRAM        : {0:N1} / {1:N1} GB" -f
            $Overview.GpuVramUsedGB,
            $Overview.GpuVramTotalGB
        )

    }
    else {

        Write-Host "  Telemetry unavailable"

    }

    Write-Host ""

    Write-Host "NETWORK" -ForegroundColor Cyan

    Write-Host (
        "  Download    : {0}" -f
        (Format-TransferRate $Overview.DownloadRate)
    )

    Write-Host (
        "  Upload      : {0}" -f
        (Format-TransferRate $Overview.UploadRate)
    )

    Write-Host ""

    Write-Host "DISK" -ForegroundColor Cyan

    if ($null -ne $Overview.DiskBusy) {

        Write-Host (
            "  Busy        : {0} {1:N1}%" -f
            (New-UsageBar $Overview.DiskBusy),
            $Overview.DiskBusy
        )

        Write-Host (
            "  Read        : {0}" -f
            (Format-TransferRate $Overview.DiskRead)
        )

        Write-Host (
            "  Write       : {0}" -f
            (Format-TransferRate $Overview.DiskWrite)
        )

    }
    else {

        Write-Host "  Telemetry unavailable"

    }

    Write-Host ""
    Write-Host "Ctrl+C to exit" -ForegroundColor DarkGray
    Write-Host ""
}

Export-ModuleMember -Function Show-SystemPulseOverview