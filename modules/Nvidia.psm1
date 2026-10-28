function Get-NvidiaInfo {

    $cmd = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue

    if (-not $cmd) {
        $cmd = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    }

    if (-not $cmd) {
        return $null
    }

    try {

        $line = & $cmd.Source `
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
            Name       = $v[0]
            Load       = [double]$v[1]
            VramUsed   = [double]$v[2]
            VramTotal  = [double]$v[3]
            Temp       = [double]$v[4]
        }

    }
    catch {
        return $null
    }
}

Export-ModuleMember -Function Get-NvidiaInfo