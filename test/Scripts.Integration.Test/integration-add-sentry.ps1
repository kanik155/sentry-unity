﻿param($arg)

. ./test/Scripts.Integration.Test/IntegrationGlobals.ps1

$unityPath = FormatUnityPath $arg

ClearUnityLog

Write-Host -NoNewline "Injecting Editor script"
$stdout = New-Item -Path "$NewProjectAssetsPath" -Name "Editor" -ItemType "directory"
Copy-Item "$IntegrationScriptsPath/SentrySetup.cs"      -Destination "$NewProjectAssetsPath/Editor"
Copy-Item "$IntegrationScriptsPath/SentrySetup.cs.meta" -Destination "$NewProjectAssetsPath/Editor"
Write-Output " OK"

Write-Host -NoNewline "Applying Sentry package to the project:"
$UnityProcess = Start-Process -FilePath "$unityPath/$Unity" -ArgumentList "-batchmode", "-projectPath ", "$NewProjectPath", "-logfile", "$NewProjectLogPath/$LogFile" -PassThru
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
ElseIf ($null -ne ($stdout | select-string "SUCCESS"))
{
    Write-Output ""
    Write-Output "Sentry added!!"
}
Else
{
    Throw "Unity exited but failed to add Sentry package."
}

Write-Host -NoNewline "Updating test files "
Remove-Item -Path "$NewProjectAssetsPath/Scripts/SmokeTester.cs"
Remove-Item -Path "$NewProjectAssetsPath/Scripts/SmokeTester.cs.meta"
Copy-Item "$UnityOfBugsPath/Assets/Scripts/SmokeTester.cs"      -Destination "$NewProjectAssetsPath/Scripts"
Copy-Item "$UnityOfBugsPath/Assets/Scripts/SmokeTester.cs.meta" -Destination "$NewProjectAssetsPath/Scripts"
Write-Output " OK"