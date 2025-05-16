# Set-ExecutionPolicy RemoteSigned
#(Get-Date).DayOfWeek
#(Get-Date).Hour
#(Get-Date).Minute
# Write-Output 'test'
# New-Item -ItemType File -Path 'C:\Users\Public\NoShutdown' -Force -ErrorAction Stop
# (cmd) copy NUL C:\Users\Public\NoShutdown
# (cmd) del C:\Users\Public\NoShutdown

$Logfile = "C:\Users\frede\Documents\timedShutdown.log"
function WriteLog
{
Param ([string]$LogString)
$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
$LogMessage = "$Stamp $LogString"
Add-content $LogFile -value $LogMessage
}

$CurrentDateTime = Get-Date

$NoShutdownPath = 'C:\Users\Public\NoShutdown'
$NoShutdown = Get-Item -Path $NoShutdownPath -ErrorAction Ignore 
if ( $NoShutdown ) {
    # no time limit

	if ( $NoShutdown.LastWriteTime.Date -ne $CurrentDateTime.Date )	{
        # remove old "NoShutdown" file
		Remove-Item -Path $NoShutdownPath -Force
	}

} else {

    $DayTimeMinute = $CurrentDateTime.Hour * 60 + $CurrentDateTime.Minute

    $DayTimeMin = 11 * 60 + 30
    $DayTimeMax = 12 * 60 + 30

    WriteLog "DayTimeMin: $DayTimeMin  DayTimeMax: $DayTimeMax  DayTimeMinute: $DayTimeMinute"
	if ( ($DayTimeMinute -ge $DayTimeMin) -and ($DayTimeMinute -le $DayTimeMax)) {
        WriteLog "Shutdown 11:30-12:30"
        shutdown /s /d u:0:0 /c "Pas de télé jusqu'à 12h30 (ou sinon demande à Papa)."
	}

    $DayTimeMin = 18 * 60 + 30
    $DayTimeMax = 19 * 60 + 30

    WriteLog "DayTimeMin: $DayTimeMin  DayTimeMax: $DayTimeMax  DayTimeMinute: $DayTimeMinute"
	if ( ($DayTimeMinute -ge $DayTimeMin) -and ($DayTimeMinute -le $DayTimeMax)) {
        WriteLog "Shutdown 18:30-19:30"
        shutdown /s /d u:0:0 /c "Pas de télé jusqu'à 19h30 (ou sinon demande à Papa)."
	}    

    # control max screen time

    $LogonHt = @{
        'LogName'      = 'System'
        'ProviderName' = 'Microsoft-Windows-Winlogon'
        'ID'           = 7001
        'StartTime'    = [datetime]::Today
    }
    $LogonEvents = Get-WinEvent -ComputerName $env:COMPUTERNAME -FilterHashtable $LogonHt
    $LogonTimes = $LogonEvents.TimeCreated

    $LogoffHt = @{
        'LogName'      = 'System'
        'ProviderName' = 'Microsoft-Windows-Winlogon'
        'ID'           = 7002
        'StartTime'    = [datetime]::Today
    }
    $LogoffEvents = Get-WinEvent -ComputerName $env:COMPUTERNAME -FilterHashtable $LogoffHt -Oldest -ErrorAction Ignore
    if (-not $LogoffEvents) {
        $LogoffTimes = Get-Date
    } else {
        $LogoffTimes = $LogoffEvents.TimeCreated
    }

    $DailyScreenTime = 0;
    $PreviousLogonTime = $null;
    $PreviousLogoffTime = $null;
    foreach ($LogonTime in $LogonTimes) {
        $LogoffTime = $LogoffTimes | ? { $_ -gt $LogonTime } | select -First 1

        # Missing LogoffTime:
        if (-not $LogoffTime) { # We didn't found any logoffTime after the logonTime
            if ($PreviousLogonTime) {
                $LogoffTime = $PreviousLogonTime
            } else {
                $LogoffTime = Get-Date
            }
        } elseif (($PreviousLogonTime) -and ($LogoffTime -gt $PreviousLogonTime)) { # We found a logoffTime but is value is too late
            $LogoffTime = $PreviousLogonTime
        }

        $LogonDuration = [math]::Round((New-TimeSpan -Start $LogonTime -End $LogoffTime).TotalHours, 2)

        $DailyScreenTime = $DailyScreenTime + $LogonDuration
        WriteLog "LogonTime: $LogonTime  LogoffTime: $LogoffTime"
        $PreviousLogonTime = $LogonTime;
        $PreviousLogoffTime = $LogoffTime;
    }

    WriteLog "DailyScreenTime: $DailyScreenTime"

    if ( $DailyScreenTime -ge 6 ) {
        WriteLog "Shutdown 6h"
        shutdown /s /d u:0:0 /c "Maximum 6h de télé aujourd'hui (ou sinon demande à Papa)."
	}
}


