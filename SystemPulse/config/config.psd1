@{
    RefreshInterval = 1

    GraphHistoryLength = 60

    DefaultView = "Overview"

    CompactMode = $false

    EnableNvidia = $true

    EnableSensors = $true

    Colors = @{
        Header   = "Cyan"
        Accent   = "Green"
        Warning  = "Yellow"
        Critical = "Red"
        Value    = "White"
    }

    TemperatureThresholds = @{
        Warning = 75
        Critical = 90
    }

    Network = @{
        SelectedAdapter = "*"
    }
}