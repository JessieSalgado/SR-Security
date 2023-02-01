# SR-Security

## Instructions
* Download the [repo](https://github.com/JessieSalgado/SR-Security/archive/refs/heads/master.zip) 
* Unblock the zip file by right-clicking and select properties
    * Check the box labeled Unblock and click OK.
* Extract the zip file to the modules folder location.
    * %USERPROFILE%\Documents\PowerShell\Modules
    * %USERPROFILE%\Documents\WindowsPowerShell\Modules
* If the root folder has the branch name on it remove it.
    * SR-Security-main --> SR-Security
* Launch a PowerShell window
    * You may need to launch it as an administrator
* For a list of commands currently available in this module run the following:
    * Get-Command -Module SR-Security -ListAvailable.

## Notes
Current versions of PowerShell breaks the tab completion of the Service Parameter in Import-ServiceCertificate CMDLET if the Password parameter is called first.
Make sure to always call the service parameter before the password one.