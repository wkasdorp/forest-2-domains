#Requires -Version 4
#
# set policy for the whole system.
#
Set-ExecutionPolicy Unrestricted -Force

#
# Install required DSC modules before we get started. 
#
Install-PackageProvider -Name NuGet -Force
Install-Module -Name ComputerManagementDSC -Force
Install-Module -Name xActiveDirectory -Force
Install-Module -Name xNetworking -Force
Install-Module -Name xStorage -Force

