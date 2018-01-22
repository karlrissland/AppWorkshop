# Variables
$instanceName = $env:COMPUTERNAME
$loginName = "TestUser1"
$dbUserName = "TestUser1"
$password = "P2ssw0rd"
$databaseName = "testDB"
$databaseRole = "db_owner"

# Install Nuget, needed to install DSC modules via PowerShellGet
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install DSC modules used by DSC Scripts run via DSC Extension
install-module -name xSqlServer -Force

# Import SQL Server module
Import-Module SQLPS -DisableNameChecking

# Create SQL Server Object
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

# Change authentication mode to mixed
$server.Settings.LoginMode = "Mixed"
$server.Alter()

# Restart SQL Service, think this is needed to pickup the security mode change
Restart-Service  MSSQLSERVER -Force

# Create SQL Server Object
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

# Create new database
$db = New-Object Microsoft.SqlServer.Management.Smo.Database($server,$databaseName)
$db.Create()
Write-Host("Database  $databaseName created successfully.")

# Drop login if it exists
if ($server.Logins.Contains($loginName))  
{   
    Write-Host("Deleting the existing login $loginName.")
       $server.Logins[$loginName].Drop() 
}

# Add login
$login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $server, $loginName
$login.LoginType = "SqlLogin"
$login.PasswordExpirationEnabled = $false
$login.Create($password)
Write-Host("Login $loginName created successfully.")

# Add user to database
$dbUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList $db, $dbUserName
$dbUser.Login = $loginName
$dbUser.Create()
Write-Host("User $dbUser created successfully.")

# Assign database role for a new user
$dbrole = $server.Databases[$databaseName].Roles[$databaseRole]
$dbrole.AddMember($dbUserName)
$dbrole.Alter()
Write-Host("User $dbUser successfully added to $databaseRole role.")
