## Dev Workstation Configuration Script

Param (
	[string]$repoUri,
	[string]$adminUserName,
	[string]$adminUserPassword,
	[string]$webSrvUri,
	[string]$dbSrvUri,
	[string]$dbName,
	[string]$dbUserName,
	[string]$dbUserPassword
)

#Clone Repo
mkdir 'c:\Source'
cd 'c:\Source'
git clone $repoUri

#Install Chocolatey and packages
Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
Start-Sleep -Seconds 3
#Install NuGet
& choco install nuget.commandline 

#Build and Package App

#Restore NuGet packages
nuget restore C:\Source\AppWorkshop\IaaS2PaaSWeb\IaaS2PaaSWeb.sln

#Build App using VS Tools
$build_bat_file = Join-Path -Path $PSScriptRoot -ChildPath "doBuild.bat"
if (!(Test-Path $build_bat_file)) {
    Add-Content -Path $build_bat_file -Value "call `"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\vsdevcmd\core\vsdevcmd_start.bat`""
    Add-Content -Path $build_bat_file -Value "call `"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\vsdevcmd\core\dotnet.bat`""
    Add-Content -Path $build_bat_file -Value "call `"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\vsdevcmd\core\msbuild.bat`""
    Add-Content -Path $build_bat_file -Value "msbuild C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\partsunlimitedwebsite.csproj /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true"
}
Start-Process "cmd.exe" "/c $build_bat_file" -Wait
Remove-Item -Path $build_bat_file

## Deploy Webapp

#Recreate Parameters File with correct values
$SettingsFile = "<?xml version=""1.0"" encoding=""utf-8""?>"
$SettingsFile += "<parameters>"
$SettingsFile += "<setParameter name=""IIS Web Application Name"" value=""Default Web Site"" />"
$SettingsFile += "<setParameter name=""DefaultConnectionString-Web.config Connection String"" value=""Server=" + $dbSrvUri + ";Database=" + $dbName + "; User Id=" + $dbUserName + "; password= " + $dbUserPassword + """/>"
$SettingsFile += "</parameters>"

Set-Content -Path C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\obj\Debug\Package\partsunlimitedwebsite.SetParameters.xml -Value $SettingsFile

#Deploy Website
C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\obj\Debug\Package\partsunlimitedwebsite.deploy.cmd /Y /M:$webSrvUri/MSDeployAgentService /U:$adminUserName /P:$adminUserPassword

#Add startup bat to install additional packages on sign in
$choco_exe = "C:\ProgramData\chocolatey\bin\choco.exe"
$install_packages_bat = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\install_packages.bat"
@('postman') | ForEach-Object {
	Add-Content -Path $install_packages_bat -Value "$choco_exe install -y $_"
}
#Install Google Chrome browser
& choco install -y googlechrome