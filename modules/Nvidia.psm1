function Get-NvidiaInfo {

    $cmd =
        Get-Command nvidia-smi.exe `
        -ErrorAction SilentlyContinue

    if (-not $cmd) {
        $cmd =
            Get-Command nvidia-smi `
            -ErrorAction SilentlyContinue
    }

    if (-not $cmd) {
        return $null
    }

    try {

        $line =
            & $cmd.Source `
            --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu `
            --format=csv,noheader,nounits 2>$null |
            Select-Object -First 1

        if (-not $line) {
            return $null
        }

        $v = $line -split ',\s*'

        if ($v.Count -lt 5) {
            return $null
        }

        [pscustomobject]@{
            Name      = $v[0]
            Load      = [double]$v[1]
            VramUsed  = [double]$v[2]
            VramTotal = [double]$v[3]
            Temp      = [double]$v[4]
        }
    }
    catch {
        return $null
    }
}

function Get-NvidiaTopProcess {

    $cmd =
        Get-Command nvidia-smi.exe `
        -ErrorAction SilentlyContinue

    if (-not $cmd) {
        $cmd =
            Get-Command nvidia-smi `
            -ErrorAction SilentlyContinue
    }

    if (-not $cmd) {
        return $null
    }

    try {

        $rows =
            & $cmd.Source pmon -c 1 2>$null

        if (-not $rows) {
            return $null
        }

        $best = $null
        $highest = -1

        foreach ($row in $rows) {

            if (
                $row.Trim().StartsWith("#") -or
                [string]::IsNullOrWhiteSpace($row)
            ) {
                continue
            }

            $parts =
                $row -split '\s+'

            if ($parts.Count -lt 5) {
                continue
            }

            $pid =
                $parts[1]

            $sm =
                $parts[3]

            if (
                $pid -eq "-" -or
                $sm -eq "-"
            ) {
                continue
            }

            $smLoad =
                [double]$sm

            if ($smLoad -gt $highest) {

                try {

                    $process =
                        Get-Process `
                        -Id $pid `
                        -ErrorAction Stop

                    $highest =
                        $smLoad

                    $best =
                        [pscustomobject]@{
                            Name    = $process.ProcessName
                            Percent = $smLoad
                        }
                }
                catch {
                }
            }
        }

        return $best
    }
    catch {
        return $null
    }
}

Export-ModuleMember -Function `
    Get-NvidiaInfo, `
    Get-NvidiaTopProcess