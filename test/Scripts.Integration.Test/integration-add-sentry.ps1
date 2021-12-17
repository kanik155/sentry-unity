﻿param($path)

. ./test/Scripts.Integration.Test/IntegrationGlobals.ps1

ShowIntroAndValidateRequiredPaths "True" "Add Sentry" $path

Write-Output "Removing Log"
ClearUnityLog

Write-Host -NoNewline "Injecting Editor script"
$stdout = New-Item -Path "$NewProjectAssetsPath" -Name "Editor" -ItemType "directory" -ErrorAction Stop
Copy-Item "$IntegrationScriptsPath/SentrySetup.cs"      -Destination "$NewProjectAssetsPath/Editor" -ErrorAction Stop
Copy-Item "$IntegrationScriptsPath/SentrySetup.cs.meta" -Destination "$NewProjectAssetsPath/Editor" -ErrorAction Stop
Write-Output " OK"

Write-Host -NoNewline "Applying Sentry package to the project:"
$UnityProcess = Start-Process -FilePath "$Global:UnityPath/$Unity" -ArgumentList "-batchmode", "-projectPath ", "$NewProjectPath", "-logfile", "$NewProjectLogPath/$LogFile" -PassThru
Write-Output " OK"

WaitLogFileToBeCreated 30

Write-Output "Waiting for Unity to add Sentry to  the project."
$stdout = TrackCacheUntilUnityClose $UnityProcess "Sentry setup: SUCCESS" "Sentry setup: FAILED"

Write-Output "Removing Editor script"
Remove-Item -LiteralPath "$NewProjectAssetsPath/Editor" -Force -Recurse -ErrorAction Stop

Write-Output $stdout
If ($UnityProcess.ExitCode -ne 0)
{
    $exitCode = $UnityProcess.ExitCode
    Throw "Unity exited with code $exitCode"
}
ElseIf (($stdout | select-string "SUCCESS") -ne $null)
{
    Write-Output ""
    Write-Output "Sentry added!!"
}
Else
{
    Throw "Unity exited but failed to add Sentry package."
}

Write-Host -NoNewline "Updating test files "
Remove-Item -Path "$NewProjectAssetsPath/Scripts/SmokeTester.cs" -Force
Remove-Item -Path "$NewProjectAssetsPath/Scripts/SmokeTester.cs.meta" -Force
Copy-Item "$UnityOfBugsPath/Assets/Scripts/SmokeTester.cs"      -Destination "$NewProjectAssetsPath/Scripts" -ErrorAction Stop
Copy-Item "$UnityOfBugsPath/Assets/Scripts/SmokeTester.cs.meta" -Destination "$NewProjectAssetsPath/Scripts" -ErrorAction Stop
Write-Output " OK"
