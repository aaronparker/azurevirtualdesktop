#description: Downloads the Microsoft Virtual Desktop Optimization Tool and optimises the OS. Ensure 014_RolesFeatures.ps1 and 015_Customise.ps1 are run
#execution mode: Combined
#tags: Image, Optimise

$ScriptName = "Microsoft Virtual Desktop Optimization Tool"
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Start: $ScriptName."

#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Vdot"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download Microsoft Virtual Desktop Optimization Tool
$App = Get-EvergreenApp -Name "MicrosoftVdot" | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

# Run Microsoft Virtual Desktop Optimization Tool
Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
$Installer = Get-ChildItem -Path $Path -Recurse -Include "Windows_VDOT.ps1"
Push-Location -Path $Installer.Directory
$params = @{
    Optimizations = "ScheduledTasks", "Autologgers", "Services", "NetworkOptimizations"
    AcceptEULA    = $true
    Restart       = $false
    Verbose       = $false
}
& $Installer.FullName @params
Pop-Location

$StopWatch.Stop()
Write-Host "Stop: $ScriptName. Time: $($StopWatch.Elapsed)"
