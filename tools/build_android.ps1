$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$engine = 'C:\godot\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe'
$sdkDirectory = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$env:ANDROID_HOME = $sdkDirectory
$env:JAVA_HOME = 'C:\jdk\jdk-17.0.0.1'
$projectText = Get-Content -LiteralPath (Join-Path $projectDirectory 'project.godot') -Raw
$version = [regex]::Match($projectText, 'config/version="([^"]+)"').Groups[1].Value
if (-not $version) { throw 'Project version is missing' }
$output = Join-Path $projectDirectory "build\Cosmorace-$version-debug.apk"
$log = Join-Path $projectDirectory 'build\export-android.log'
$started = [DateTime]::UtcNow
$errorLog = Join-Path $projectDirectory 'build\export-android.stderr.log'
$process = Start-Process -FilePath $engine -ArgumentList @('--headless','--path',('"' + $projectDirectory + '"'),'--export-debug','Android',('"' + $output + '"')) -WindowStyle Hidden -PassThru -RedirectStandardOutput $log -RedirectStandardError $errorLog
$process.WaitForExit()
# Windows PowerShell can lose ExitCode after WaitForExit; also require the export marker.
if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) { throw "Export failed; inspect $log and $errorLog" }
$exportLog = Get-Content -LiteralPath $log -Raw
$exportLog = [regex]::Replace($exportLog, '\x1B\[[0-9;]*[A-Za-z]', '')
if ($exportLog -notmatch '\[\s*DONE\s*\] export') { throw "Export did not complete; inspect $log" }
if (-not (Test-Path -LiteralPath $output)) { throw 'APK missing' }
if ((Get-Item -LiteralPath $output).LastWriteTimeUtc -lt $started.AddSeconds(-2)) { throw 'APK is stale' }
& (Join-Path $sdkDirectory 'build-tools\36.0.0\apksigner.bat') verify $output
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
Write-Output "APK ready: $output"
