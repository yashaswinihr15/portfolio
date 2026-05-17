$WatchPath = "F:\devops\portfolio"

Write-Host ""
Write-Host "================================="
Write-Host " Portfolio Auto-Deploy Watcher"
Write-Host "================================="
Write-Host "Watching : $WatchPath"
Write-Host "Jenkins  : http://localhost:8090/job/portfolio-pipeline"
Write-Host "Triggers : .html .css .js"
Write-Host ""
Write-Host "Watcher is active. Edit and save any .html / .css / .js file to auto-deploy."
Write-Host ""

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$watcher.EnableRaisingEvents = $true

Register-ObjectEvent $watcher Changed -Action {
    $path = $Event.SourceEventArgs.FullPath
    $ext = [System.IO.Path]::GetExtension($path)

    if($ext -in ".html",".css",".js") {
        Write-Host "Change detected: $path"
        Write-Host "Triggering deployment..."

        Invoke-WebRequest `
        -Uri "http://localhost:8090/job/portfolio-pipeline/build" `
        -UseBasicParsing
    }
}

while ($true) {
    Start-Sleep -Seconds 2
}