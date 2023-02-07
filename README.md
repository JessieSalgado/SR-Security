# SR-Security

## Instructions
Install the module via [PowerShell Gallery][1] or [GitHub][2] Repository.

`Install-Module -Name SR-Security`

* Some of the CMDLETS will require PowerShell to be elevated.
  * `Add-CertificatePrivateKeyPermission`
  * `Import-ServiceCertificate`
* For a list of commands currently available in this module run the following:
    * `Get-Command -Module SR-Security -ListAvailable`
* Use Get-Help to get more information on each CMDLET
  * `Get-Help Get-CertificatePrivateKeyFile -Full`

---

## Notes
Current versions of PowerShell breaks the tab completion of the Service Parameter in Import-ServiceCertificate CMDLET if the Password parameter is called first.
Make sure to always call the service parameter before the password one.

[1]: <https://www.powershellgallery.com/packages/SR-Security> "SR-Security"
[2]: <https://github.com/JessieSalgado/SR-Security> "Source Code"