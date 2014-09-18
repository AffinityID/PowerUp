@echo off

set parameters=%*
if "%parameters%" == "" goto USAGE

:RUN
	set policyCmd=$execPolicy = Get-ExecutionPolicy; if (!($execPolicy -eq 'Unrestricted')) { Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process }
	set execCmd=%~dp0RunPSake.ps1 %parameters%

	powershell -inputformat none -command "%policyCmd%;%execCmd%"
	exit /B %errorlevel%

:USAGE
	echo Usage: 
	echo 	Run.bat ^<Parameters^>
	echo Parameters:
	echo 	-operation [operationName:string] 	- The operation you would like to run.
	echo 	-buildNumber [buildNumber:int] 		- (Optional) The build number for this run. Defaults to 0.
	echo 	-operationProfile [profileName:string] 	- (Optional) The profile that you would like to use. 
	echo 	-task [taskName:string] 		- (Optional) The task to execute. Defaults to the "default" task.
	exit /B