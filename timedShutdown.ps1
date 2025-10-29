# Define constants and file paths
$NoShutdownFilePath = "C:\Users\Public\NoShutdown"
$LogFilePath = "C:\Users\frede\Documents\timedShutdown.log"
$MaxLogIntervalSeconds = 330 # 5 minutes + 30 seconds
$MinLogIntervalSeconds = 270 # 5 minutes - 30 seconds
$MaxAllowedTime = New-TimeSpan -Hours 6

# Get current time for checks and logging
$CurrentTime = Get-Date
$TodayString = $CurrentTime.ToString("yyyy-MM-dd")

# --- Function to check if a file was created today ---
function Test-FileCreatedToday {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    if (Test-Path $Path) {
        $CreationDate = (Get-Item $Path).CreationTime.Date
        $Today = (Get-Date).Date
        return $CreationDate -eq $Today
    }
    return $false
}

# --- 1. Check for "NoShutdown" file ---
if (Test-Path $NoShutdownFilePath) {
    if (Test-FileCreatedToday -Path $NoShutdownFilePath) {
        # 1.1 - File is present and created today: Do nothing and exit.
        Write-Host "NoShutdown file is present and created today. Exiting."
        exit
    } else {
        # 1.2 - File was created a previous day: Delete the file.
        Write-Host "NoShutdown file is present but was created on a previous day. Deleting."
        Remove-Item $NoShutdownFilePath -Force
    }
}

# Ensure the log file directory exists
$LogDir = Split-Path -Parent $LogFilePath
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory | Out-Null
}

# --- Remove logs written before today ---
Write-Host "Cleaning up old log entries..."
$AllLogs = @()
if (Test-Path $LogFilePath) {
    # Read all log entries and filter for today's date
    # Only keep lines that start with today's date string (yyyy-MM-dd)
    $TodayLogs = Get-Content $LogFilePath | Where-Object { 
        $_ -match "^\d{4}-\d{2}-\d{2}" -and $_ -like "$TodayString*" 
    }
    
    # Overwrite the log file with only today's entries
    $TodayLogs | Out-File $LogFilePath -Encoding UTF8 -Force
}

# --- 4. Logging and Time Calculation (Modified to use $TodayLogs from cleanup) ---

$TotalTimeLogged = New-TimeSpan -Seconds 0

if ($TodayLogs.Count -gt 0) {
    # Convert log strings to DateTime objects
    $LogTimes = $TodayLogs | ForEach-Object { [datetime]($_ -split ' - ')[0] } | Sort-Object

    # Add the current time to the list for the final interval calculation
    $LogTimes += $CurrentTime

    # Calculate total valid duration
    for ($i = 0; $i -lt $LogTimes.Count - 1; $i++) {
        $Time1 = $LogTimes[$i]
        $Time2 = $LogTimes[$i+1]
        $Duration = $Time2 - $Time1

        # Check if the duration is within the 5 minutes +/- 30 seconds range
        if ($Duration.TotalSeconds -ge $MinLogIntervalSeconds -and $Duration.TotalSeconds -le $MaxLogIntervalSeconds) {
            $TotalTimeLogged += $Duration
        }
    }
} else {
    # If no logs today, the first log will be the current time, total time is 0 for now.
    $TotalTimeLogged = New-TimeSpan -Seconds 0
}

# Format the total time for the log entry
$TotalTimeFormatted = "{0:hh\:mm\:ss}" -f $TotalTimeLogged

# Create the new log entry
$NewLogEntry = "$($CurrentTime.ToString("yyyy-MM-dd HH:mm:ss")) - Total valid run time today: $TotalTimeFormatted"

# Write the new log entry
Add-Content -Path $LogFilePath -Value $NewLogEntry

Write-Host "Current Total Valid Time: $TotalTimeFormatted"

# --- Total Time Limit Check ---
if ($TotalTimeLogged -ge $MaxAllowedTime) {
    $Message = "Maximum 6h de télé aujourd'hui (ou sinon demande à Papa)."
    Write-Host "Total time check: 6-hour limit reached. Triggering shutdown."
    shutdown /s /t 30 /c "$Message"
    exit
}

# --- 2. Check for 11:30 to 12:30 shutdown window ---
$TimeSpan1 = New-TimeSpan -Hours 11 -Minutes 30
$TimeSpan2 = New-TimeSpan -Hours 12 -Minutes 30
$CurrentTimeOfDay = $CurrentTime.TimeOfDay

if ($CurrentTimeOfDay -ge $TimeSpan1 -and $CurrentTimeOfDay -lt $TimeSpan2) {
    $Message = "Pas de télé jusqu'à 12h30 (ou sinon demande à Papa)."
    Write-Host "Time check 1: Triggering shutdown."
    shutdown /s /t 30 /c "$Message"
    exit
}

# --- 3. Check for 18:30 to 19:30 shutdown window ---
$TimeSpan3 = New-TimeSpan -Hours 18 -Minutes 30
$TimeSpan4 = New-TimeSpan -Hours 19 -Minutes 30

if ($CurrentTimeOfDay -ge $TimeSpan3 -and $CurrentTimeOfDay -lt $TimeSpan4) {
    $Message = "Pas de télé jusqu'à 19h30 (ou sinon demande à Papa)."
    Write-Host "Time check 2: Triggering shutdown."
    shutdown /s /t 30 /c "$Message"
    exit
}

Write-Host "Script finished successfully. No shutdown triggered."
