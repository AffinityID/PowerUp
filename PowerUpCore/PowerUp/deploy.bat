@echo off

if not '%1'=='' goto RUN

:NOENVIRONMENT
	@echo on
	echo Deployment environment parameter is required
	echo e.g. deploy production	
	exit /B

:RUN
	call _powerup\deploy\core\ensure_prerequisites.bat
	
if not '%2'=='' goto RUNWITHTASK	
powershell -inputformat none -command ".\_powerup\deploy\core\deploy_with_psake.ps1 -buildFile .\deploy.ps1 -deploymentProfile %1";exit $LastExitCode

goto END

:RUNWITHTASK
powershell -inputformat none -command ".\_powerup\deploy\core\deploy_with_psake.ps1 -buildFile .\deploy.ps1 -deploymentProfile %1 -tasks %2";exit $LastExitCode

:END