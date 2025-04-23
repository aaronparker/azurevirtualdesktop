#description: Runs a Microsoft Defender antivirus quick scan. Use in a desktop image to ensure the scan data is up to date
#execution mode: Combined
#tags: Antivirus, Image

$ScriptName = "Defender Full Scan"
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Start: $ScriptName."

Update-MpSignature -UpdateSource "MicrosoftUpdateServer"
Start-MpScan -ScanType "Quick"

$StopWatch.Stop()
Write-Host "Stop: $ScriptName. Time: $($StopWatch.Elapsed)"
