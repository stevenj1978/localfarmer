﻿$path = "C:\localfarmerz"
$filter = "*.*"
$logFile = "$path\watch_and_push.log"
$debounceSeconds = 300  # 5-minute debounce period

# Initialize FileSystemWatcher
$fsw = New-Object IO.FileSystemWatcher $path, $filter
$fsw.IncludeSubdirectories = $true
$fsw.EnableRaisingEvents = $true
$fsw.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'

# Exclude patterns
$excludePatterns = @(
    '\.git',
    'node_modules',
    '\.log$',
    'watch_and_push\.ps1'
)

# Track last commit time for debouncing
$script:lastCommitTime = [DateTime]::MinValue
$script:pendingChanges = $false

# Define the action to take on events
$action = {
    $changedPath = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    # Check if path should be excluded
    foreach ($pattern in $using:excludePatterns) {
        if ($changedPath -match $pattern) {
            return
        }
    }
    
    # Log the change detection
    "[$timestamp] Change detected: $changeType on $changedPath" | Out-File -FilePath $using:logFile -Append
    $script:pendingChanges = $true

    # Check if enough time has passed since last commit
    if (([DateTime]::Now - $script:lastCommitTime).TotalSeconds -ge $using:debounceSeconds) {
        try {
            Set-Location $using:path
            
            # Check if we're on development branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            if ($currentBranch -ne "development") {
                "[$timestamp] Warning: Not on development branch. Currently on: $currentBranch" | 
                    Out-File -FilePath $using:logFile -Append
                return
            }
            
            # Check if there are actual changes to commit
            $status = git status --porcelain
            if ($status -and $script:pendingChanges) {
                # Stage changes
                git add .
                
                # Create meaningful commit message
                $commitMessage = "Auto-commit: Development changes at $timestamp`n`n"
                $commitMessage += "Changed files:`n"
                $status | ForEach-Object { $commitMessage += "$_`n" }
                
                git commit -m $commitMessage
                git push origin development
                
                $script:lastCommitTime = [DateTime]::Now
                $script:pendingChanges = $false
                
                "[$timestamp] Successfully pushed changes to GitHub development branch." | 
                    Out-File -FilePath $using:logFile -Append
            }
        }
        catch {
            "[$timestamp] Error during git operations: $_" | Out-File -FilePath $using:logFile -Append
        }
    }
}

# Register event handlers
Register-ObjectEvent $fsw 'Changed' -Action $action -SourceIdentifier 'FileChanged'
Register-ObjectEvent $fsw 'Created' -Action $action -SourceIdentifier 'FileCreated'
Register-ObjectEvent $fsw 'Deleted' -Action $action -SourceIdentifier 'FileDeleted'
Register-ObjectEvent $fsw 'Renamed' -Action $action -SourceIdentifier 'FileRenamed'

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] File watcher started. Monitoring $path" | 
    Out-File -FilePath $logFile -Append

# Keep the script running
try {
    while ($true) { Start-Sleep -Seconds 1 }
}
finally {
    # Cleanup when script is stopped
    Get-EventSubscriber | Unregister-Event
    "[$timestamp] File watcher stopped." | Out-File -FilePath $logFile -Append
}
