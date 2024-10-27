# watch_and_push.ps1

$path = "C:\localfarmerz"
$filter = "*.*"
$logFile = "$path\watch_and_push.log"

# Initialize FileSystemWatcher
$fsw = New-Object IO.FileSystemWatcher $path, $filter
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

# Log the initialization
"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initializing FileSystemWatcher on $path with filter $filter." | Out-File -FilePath $logFile -Append

# Define the action to take on events
$action = {
    $changedPath = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # Log the change detection
    "[$timestamp] Change detected: $changeType on $changedPath" | Out-File -FilePath $using:logFile -Append

    Start-Sleep -Seconds 5

    try {
        Set-Location $using:path
        git add .
        git commit -m "Automatic commit on $timestamp"
        git push origin main

        "[$timestamp] Successfully pushed changes to GitHub." | Out-File -FilePath $using:logFile -Append
    }
    catch {
        "[$timestamp] Error during git operations: $_" | Out-File -FilePath $using:logFile -Append
    }
}

# Register event handlers with unique identifiers
Register-ObjectEvent $fsw 'Changed' -Action $action -SourceIdentifier 'FileChanged'
Register-ObjectEvent $fsw 'Created' -Action $action -SourceIdentifier 'FileCreated'
Register-ObjectEvent $fsw 'Deleted' -Action $action -SourceIdentifier 'FileDeleted'
Register-ObjectEvent $fsw 'Renamed' -Action $action -SourceIdentifier 'FileRenamed'

# Log the event registration
"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Event handlers registered: Changed, Created, Deleted, Renamed." | Out-File -FilePath $logFile -Append

# Keep the script running
while ($true) {
    Start-Sleep -Seconds 1
}