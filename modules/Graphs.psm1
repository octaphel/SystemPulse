function Get-SystemPulseGraphVersion {
    "0.3"
}

function New-UsageBar {

    param(
        [double]$Percent,
        [int]$Width = 20
    )

    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }

    $Filled = [math]::Round(($Percent / 100) * $Width)
    $Empty = $Width - $Filled

    "[" + ("#" * $Filled) + ("." * $Empty) + "]"
}

function Add-HistoryPoint {

    param(
        [System.Collections.ArrayList]$History,
        [double]$Value,
        [int]$MaxPoints = 60
    )

    if ($null -eq $History) {
        return
    }

    [void]$History.Add($Value)

    while ($History.Count -gt $MaxPoints) {
        $History.RemoveAt(0)
    }
}

function ConvertTo-HistoryGraph {

    param(
        [System.Collections.ArrayList]$History
    )

    if ($null -eq $History -or $History.Count -eq 0) {
        return ""
    }

    $Graph = ""

    foreach ($Value in $History) {

        if ($Value -lt 12.5) {
            $Graph += "."
        }
        elseif ($Value -lt 25) {
            $Graph += "_"
        }
        elseif ($Value -lt 37.5) {
            $Graph += "-"
        }
        elseif ($Value -lt 50) {
            $Graph += "="
        }
        elseif ($Value -lt 62.5) {
            $Graph += "+"
        }
        elseif ($Value -lt 75) {
            $Graph += "*"
        }
        elseif ($Value -lt 87.5) {
            $Graph += "#"
        }
        else {
            $Graph += "@"
        }
    }

    return $Graph
}

Export-ModuleMember -Function `
    Get-SystemPulseGraphVersion, `
    New-UsageBar, `
    Add-HistoryPoint, `
    ConvertTo-HistoryGraph