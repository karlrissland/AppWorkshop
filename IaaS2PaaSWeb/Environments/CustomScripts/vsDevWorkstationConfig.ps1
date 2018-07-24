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

$current_dir = $PSScriptRoot
if (!$current_dir) { $current_dir = Get-Location }

## Clone Repo
$repo_path = 'c:\Source'
if (!(Test-Path $repo_path)) { 
    mkdir $repo_path 
    cd $repo_path
    if (!(Test-Path "$repo_path\AppWorkshop")) {
        git clone $repoUri
    }
	cd $current_dir 
}

## Install Chocolatey and packages
if ((Get-Command choco -ErrorAction SilentlyContinue) -eq $null) {
	Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
}
#Install NuGet
if ((Get-Command nuget -ErrorAction SilentlyContinue) -eq $null) {
	& choco install nuget.commandline -y
}

## Build and Package App

#Restore NuGet packages
nuget restore C:\Source\AppWorkshop\IaaS2PaaSWeb\IaaS2PaaSWeb.sln

#Build App using VS Tools
$build_bat_file = Join-Path -Path $current_dir -ChildPath "build.bat"
if (!(Test-Path $build_bat_file)) {
    Add-Content -Path $build_bat_file -Value "call `"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\vsdevcmd\core\vsdevcmd_start.bat`""
    Add-Content -Path $build_bat_file -Value "call `"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\vsdevcmd\core\dotnet.bat`""
    Add-Content -Path $build_bat_file -Value "call `"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\vsdevcmd\core\msbuild.bat`""
    Add-Content -Path $build_bat_file -Value "msbuild `"C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\PartsUnlimitedWebsite.csproj`" /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true"
}
cmd.exe /c $build_bat_file

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

## Add startup bat to install additional packages on sign in
$choco_exe = "C:\ProgramData\chocolatey\bin\choco.exe"
$install_packages_bat = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\install_packages.bat"
if (!(Test-Path $install_packages_bat)) {
	Set-Content -Path $install_packages_bat -Value "$choco_exe install postman googlechrome -y"
}
