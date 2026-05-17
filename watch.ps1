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

# Jenkins credentials
$user = "yashaswinihr15"
$apiToken = "112cf766ed739e771d8087cbf087774f57"

# Create watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$watcher.EnableRaisingEvents = $true

$null = Register-ObjectEvent $watcher Changed -Action {

    $path = $Event.SourceEventArgs.FullPath
    $ext = [System.IO.Path]::GetExtension($path)

    if($ext -in ".html",".css",".js") {

        Write-Host ""
        Write-Host "Change detected: $path"
        Write-Host "Triggering deployment..."

        try {

            $pair = "$user`:$apiToken"

            $encoded = [Convert]::ToBase64String(
                [Text.Encoding]::ASCII.GetBytes($pair)
            )

            $crumbData = Invoke-RestMethod `
                -Uri "http://localhost:8090/crumbIssuer/api/json" `
                -Headers @{Authorization="Basic $encoded"}

            curl.exe -X POST `
            "http://localhost:8090/job/portfolio-pipeline/build?delay=0sec" `
            -H "Authorization: Basic $encoded" `
            -H "$($crumbData.crumbRequestField): $($crumbData.crumb)"

            Write-Host "Build triggered successfully"

        }
        catch {
            Write-Host "Failed to trigger Jenkins"
            Write-Host $_.Exception.Message
        }
    }
}

while($true){
    Start-Sleep -Seconds 2
}