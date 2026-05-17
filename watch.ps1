# watch.ps1 — Auto-triggers Jenkins when you save portfolio files
# Run this script once. It watches index.html, style.css, script.js
# and triggers Jenkins automatically whenever you save changes.
#
# Usage: Right-click watch.ps1 → "Run with PowerShell"
#        OR in PowerShell terminal: .\watch.ps1

# ─── CONFIGURE THESE ──────────────────────────────────────────────
$JENKINS_URL   = "http://localhost:8090"
$JOB_NAME      = "portfolio-pipeline"
$JENKINS_USER  = "yashaswinihr15"
$JENKINS_TOKEN = "112cf766ed739e771d8087cbf087774f57"   # Get from: Jenkins → admin → Configure → API Token
# ──────────────────────────────────────────────────────────────────

$WatchPath    = $PSScriptRoot      # Watches the same folder as this script
$DebounceWait = 4                  # Seconds to wait before triggering (avoids double-triggers)
$LastTrigger  = [datetime]::MinValue

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗"
Write-Host "║   Portfolio Auto-Deploy Watcher              ║"
Write-Host "╠══════════════════════════════════════════════╣"
Write-Host "║  Watching : $WatchPath"
Write-Host "║  Jenkins  : $JENKINS_URL/job/$JOB_NAME"
Write-Host "║  Triggers on: .html  .css  .js changes       ║"
Write-Host "║  Press Ctrl+C to stop.                       ║"
Write-Host "╚══════════════════════════════════════════════╝"
Write-Host ""

# Create file system watcher
$Watcher = New-Object System.IO.FileSystemWatcher
$Watcher.Path                  = $WatchPath
$Watcher.Filter                = "*.*"
$Watcher.IncludeSubdirectories = $false
$Watcher.NotifyFilter          = [System.IO.NotifyFilters]::LastWrite
$Watcher.EnableRaisingEvents   = $true

# Action block — runs when a file change is detected
$Action = {
    $file = $Event.SourceEventArgs.Name
    $now  = [datetime]::Now

    # Only react to web files
    if ($file -notmatch '\.(html|css|js)$') { return }

    # Debounce — ignore if triggered too recently (e.g. editor auto-saves)
    if (($now - $script:LastTrigger).TotalSeconds -lt $script:DebounceWait) { return }
    $script:LastTrigger = $now

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 📝 Change detected: $file"
    Write-Host "  → Triggering Jenkins pipeline..."

    try {
        $Bytes  = [Text.Encoding]::ASCII.GetBytes("${script:JENKINS_USER}:${script:JENKINS_TOKEN}")
        $B64    = [Convert]::ToBase64String($Bytes)
        $Header = @{ Authorization = "Basic $B64" }

        Invoke-WebRequest `
            -Uri     "$script:JENKINS_URL/job/$script:JOB_NAME/build" `
            -Method  POST `
            -Headers $Header `
            -UseBasicParsing | Out-Null

        Write-Host "  ✅ Jenkins build triggered!"
        Write-Host "  👉 Watch progress: $script:JENKINS_URL/job/$script:JOB_NAME"
    }
    catch {
        Write-Host "  ❌ Could not reach Jenkins: $_"
        Write-Host "  Make sure Jenkins is running (docker-compose up -d)"
        Write-Host "  and that your API token is correct in watch.ps1"
    }

    Write-Host ""
}

# Expose variables to the scriptblock scope
$script:JENKINS_URL   = $JENKINS_URL
$script:JOB_NAME      = $JOB_NAME
$script:JENKINS_USER  = $JENKINS_USER
$script:JENKINS_TOKEN = $JENKINS_TOKEN
$script:DebounceWait  = $DebounceWait
$script:LastTrigger   = $LastTrigger

Register-ObjectEvent $Watcher "Changed" -Action $Action -SourceIdentifier "PortfolioWatch"

Write-Host "✅ Watcher is active. Edit and save any .html / .css / .js file to auto-deploy."
Write-Host ""

try {
    while ($true) { Start-Sleep -Seconds 1 }
}
finally {
    Unregister-Event -SourceIdentifier "PortfolioWatch" -ErrorAction SilentlyContinue
    $Watcher.Dispose()
    Write-Host ""
    Write-Host "⛔ Watcher stopped."
}
