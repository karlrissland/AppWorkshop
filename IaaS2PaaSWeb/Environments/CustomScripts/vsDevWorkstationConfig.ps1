<# Custom Script for Windows #>
## Couple of things
## 1) Need to pass variables in that will allow us to construct conn string and auth against web srv
## 2) Need to pickup Web Server URI from output and pass into Dev Workstation as param we can use here
## 3) Need to make sure the Web Server is a dependency of the Dev Server, this will add a few min to the deployment

## TODO
# - pass uri from WebSrv to Main Template
# - pass uri from DBSrv to Main Template
# - pass params from WorkshopEnv to VsDevWorkstation
# - make vsDevWorkstation dependent on sqlSrv and webSrv


## Clone Repo
## note - since we are using a vs image, git is already installed
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

mkdir 'c:\Source'
cd 'c:\Source'
git clone $repoUri

## Build App##

#Set Path Variables for build
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Tools\MSVC\14.12.25827\bin\HostX86\x86"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\VC\VCPackages"
$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\TypeScript\2.5"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TestWindow"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\bin\Roslyn"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Team Tools\Performance Tools"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\Shared\Common\VSPerfCollectionTools\"
$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\"
$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\F#\4.1\Framework\v4.0\"
$env:Path += ";C:\Program Files (x86)\Windows Kits\10\bin\x86"
$env:Path += ";C:\Program Files (x86)\Windows Kits\10\bin\10.0.16299.0\x86"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\\MSBuild\15.0\bin"
$env:Path += ";C:\Windows\Microsoft.NET\Framework\v4.0.30319"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\"
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\"
$env:Path += ";C:\Program Files\Microsoft MPI\Bin\;C:\Windows\system32;C:\Windows"
$env:Path += ";C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\"
$env:Path += ";C:\Program Files\dotnet\"
$env:Path += ";C:\Program Files\Microsoft SQL Server\130\Tools\Binn\"
$env:Path += ";C:\Program Files\Git\cmd"

#Build and Package App

#this will build the debug configuration
#app package will be located at; C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\obj\Debug\Package\partsunlimitedwebsite.zip
msbuild C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\partsunlimitedwebsite.csproj /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true

## Deploy Webapp

#Recreate Parameters File with correct values
$SettingsFile = "<?xml version=""1.0"" encoding=""utf-8""?>"
$SettingsFile += "<parameters>"
$SettingsFile += "<setParameter name=""IIS Web Application Name"" value=""Default Web Site"" />"
$SettingsFile += "<setParameter name=""DefaultConnectionString-Web.config Connection String"" value=""Server=" + $dbSrvUri + ";Database=" + $dbName + "; User Id=" + $dbUserName + "; password= " + $dbUserPassword + """/>"
$SettingsFile += "</parameters>"

del C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\obj\Debug\Package\partsunlimitedwebsite.SetParameters.xml

Add-Content C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\obj\Debug\Package\partsunlimitedwebsite.SetParameters.xml $SettingsFile

#Deploy Website
C:\Source\AppWorkshop\IaaS2PaaSWeb\PartsUnlimitedWebsite\obj\Debug\Package\partsunlimitedwebsite.deploy.cmd /Y /M:$webSrvUri/MSDeployAgentService /U:$adminUserName /P:$adminUserPassword