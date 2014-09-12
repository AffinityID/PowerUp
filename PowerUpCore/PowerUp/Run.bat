@echo off

if '%1' == '' goto USAGE

:RUN
	set policyCmd=$execPolicy = Get-ExecutionPolicy; if (!($execPolicy -eq 'Unrestricted')) { Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process }

	set execCmd=%~dp0RunPSake.ps1 -operation %1
	if not '%2' == '' (
		set execCmd=%execCmd% -operationProfile %2
	)
	if not '%3' == '' (
		set execCmd=%execCmd% -task %3
	)

	powershell -inputformat none -command "%policyCmd%;%execCmd%"
	exit /B %errorlevel%

:USAGE
	echo Usage: 
	echo 	Run.bat ^<operation^> ^<profile[optional]^> ^<task[optional]^>
	exit /B