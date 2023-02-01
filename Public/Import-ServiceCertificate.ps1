<#
.SYNOPSIS
Imports a certificate to the specified services of a system.

.DESCRIPTION
This CMDLET will import a PFX certificate with private key to a Service Account's Certificate Store.

.PARAMETER PFXFile
Path to the certificate file.

.PARAMETER PFXPassword
Password for the certificate file. Make sure to enter it as a secure string.

.PARAMETER Service
The available services on the system to import the certificate to.

.PARAMETER KeepInLocalMachine
This will keep a copy of the certificate in the Local Machine Store: LocalMachine\My.

.EXAMPLE
Import-ServiceCertificate -PFXFile Cert.PFX -Service NTDS -PFXPassword (ConvertTo-SecureString -String 'Test' -AsPlainText -Force)

This example will take the certificate and specified password and import it to the Active Directory Domain Services Certificate Store

.NOTES
Current versions of PowerShell breaks the tab completion of the Service Parameter if the Password parameter is called first.
Make sure to always call the service parameter before the password one.
#>
function Import-ServiceCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = "The path to the PFX Certificate File.")]
        [string]$PFXFile,

        [Parameter(Mandatory, HelpMessage = "The password of the certificate to import.")]
        [System.Security.SecureString]$PFXPassword,

        [Parameter(HelpMessage = "Keep the certificate in the local machine certificate store.")]
        [switch]$KeepInLocalMachine
    )

    DynamicParam {
        $ParameterName = 'Service'
        $RuntimeParameterDirectory = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.HelpMessage = "List of service available on this system."

        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = (Get-CimInstance -ClassName Win32_Service).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        $AttributeCollection.Add($ValidateSetAttribute)
        $AttributeAlias = New-Object System.Management.Automation.AliasAttribute('Serv', 'S')

        $AttributeCollection.Add($AttributeAlias)

        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [array], $AttributeCollection)
        $RuntimeParameterDirectory.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDirectory
    }

    begin {
        $Service = $PSBoundParameters[$ParameterName]

        Write-Verbose -Message "Importing PFX file."
        $PFXObject = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2($PFXFile, $PFXPassword, "Exportable,MachineKeySet,PersistKeySet")

        $Thumbprint = $PFXObject.Thumbprint

        Write-Verbose -Message "Getting list of available services"
        $RootServicePath = 'HKLM:\SOFTWARE\Microsoft\Cryptography\Services'
        $LocalMachinePath = "HKLM:\SOFTWARE\Microsoft\SystemCertificates\MY\Certificates"
        $Services = $Service | ForEach-Object { Get-CimInstance -ClassName Win32_Service -Filter "Name = '$_'" }
        $LocalMachineCertPath = Join-Path -Path $LocalMachinePath -ChildPath $Thumbprint
    }
    process {
        
        Write-Verbose -Message "Importing certificate into LocalMachine\Personal"
        $certificateStore = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Store('My', 'LocalMachine')
        $certificateStore.Open('MaxAllowed')
        $certificateStore.Add($PFXObject)
        $certificateStore.Close()

        foreach ($S in $Services) {
            $Name = $S.Name

            Write-Verbose "Verifying registry path for the service."
            $ServicePath = Get-Item -Path "$RootServicePath\$Name\SystemCertificates\My\Certificates\" -ErrorAction SilentlyContinue
            If (!$ServicePath) {
                try {
                    New-Item -Path "$RootServicePath\$Name\SystemCertificates\My\Certificates\" -ItemType Key -ErrorAction Stop -Force
                }
                catch [System.Management.Automation.ActionPreferenceStopException] {
                    try {
                        Write-ErrorMessage -ExceptionType "System.Exception" `
                            -Message "Requested registry access is not allowed." `
                            -Category "PermissionDenied" `
                            -CategoryActivity "New-Item" `
                            -TargetType "Microsoft.Win32.RegistryKey" `
                            -Source "$ServicePath\$Name" `
                            -ErrorId "RegistryAccessDenied"
                    }
                    Catch {
                        $PSCmdlet.ThrowTerminatingError($PSItem)
                    }
                }
            }

            Write-Verbose -Message "Copying certificate to $($S.DisplayName)"
            $CopyParam = @{
                Path        = "$LocalMachineCertPath"
                Destination = "$RootServicePath\$Name\SystemCertificates\My\Certificates\$Thumbprint"
                Recurse     = $true
            }
            Copy-Item @CopyParam

            Add-CertificatePrivateKeyPermission -Thumbprint $Thumbprint -Identity $($S.StartName) -Permission ReadAndExecute
        }
    }
    end {
        if (!$KeepInLocalMachine) {
            Write-Verbose -Message "Perform cleanup of certificate stores."
            $removalParameters = @{
                'Path'    = "$LocalMachineCertPath"
                'Recurse' = $true
            }
            Remove-Item @removalParameters
        }
    }
}