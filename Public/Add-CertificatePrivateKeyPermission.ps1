function Add-CertificatePrivateKeyPermission {
    <#
    .SYNOPSIS
        Add a permission entry on the certificate private key.
 
    .DESCRIPTION
        This command will resolve the certificate to it's corresponding private
        key file in C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys and add a
        new access entry for the specifiy identity.

    .PARAMETER Certificate
        The Certificate Object. Make sure this certificate is located in the User's Certificate Store or LocalMachine Certificate Store.
    .PARAMETER Thumbprint
        The Thumbprint of the Certificate in the User's Certificate Store or LocalMachine Certificate Store.
    .PARAMETER Identity
        The Identity that needs permissions added to the private key.
    .PARAMETER Permission
        The Permission to assign for the private key.
    .EXAMPLE
        Add-CertificatePrivateKeyPermission -Thumbprint 'DDDDE85FF5000D36C5C88887FF2303D34F25118D' -Identity 'User' -Right 'Read'
        
        Set read permission on the specified certificate private key.
 
    .EXAMPLE
        Add-CertificatePrivateKeyPermission -Thumbprint 'DDDDE85FF5000D36C5C88887FF2303D34F25118D' -Identity 'NT SERVICE\MSSQL$INST01' -Right 'FullControl
        
        Set full control permission on the specified certificate private key
        for the SQL service account.
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    #Requires -RunAsAdministrator
    param
    (
        # The target certificate object from the local certificate store.
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate', ValueFromPipeline = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        # Certificate thumbprint, must be imported in the local certificate store.
        [Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        [System.String]
        $Thumbprint,

        # The identity to grant.
        [Parameter(Mandatory = $true)]
        [System.Security.Principal.NTAccount]
        $Identity,

        # the rights to grant.
        [Parameter(Mandatory = $true)]
        [System.Security.AccessControl.FileSystemRights]
        $Permission
    )

    $Date = Get-Date
    # Find the certificate, if the thumbprint was specified
    if ($PSCmdlet.ParameterSetName -eq 'Thumbprint') {
        Write-Verbose -Message "Searching for certificate for the specified thumbprint."
        $Certificate = Get-ChildItem -Path 'Cert:\' -Recurse |
        Where-Object { $_.Thumbprint -eq $Thumbprint -and $_.NotAfter -ge $Date -and $_.NotBefore -le $Date } |
        Select-Object -First 1

        if ($null -eq $Certificate) {
            try {
                Write-ErrorMessage -ExceptionType "System.Security.Principal.IdentityNotMappedException" `
                    -Message "The Certificate was not found." `
                    -Category "ObjectNotFound" `
                    -CategoryActivity "HasPrivateKey" `
                    -TargetType "System.Security.Cryptography.X509Certificates.X509Certificate2" `
                    -Source $Certificate.Thumbprint `
                    -ErrorId "MissingCertificate"
            }
            Catch {
                $PSCmdlet.ThrowTerminatingError($PSItem)
            }
        }
    }
    try {
        $PrivateKeyPath = Get-CertificatePrivateKeyFile -Certificate $Certificate
    }
    catch {
        try {
            Write-ErrorMessage -ExceptionType "System.IO.FileNotFoundException" `
                -Message "Unable to obtain the PrivateKey File" `
                -Category "InvalidResult" `
                -CategoryActivity "PrivateKey.Key.UniqueName" `
                -TargetType "System.String" `
                -Source $Certificate.Thumbprint `
                -ErrorId "MissingFile" `
                -Exception $PSItem
        }
        Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
    

    $ACL = Get-Acl -Path $PrivateKeyPath

    if ($ACL.Access.Where({ $_.IdentityReference -eq $Identity -and $_.FileSystemRights -eq $Permission }).Count -eq 0) {
        Write-Verbose "Add $Permission permission to $Identity on $PrivateKeyPath"

        $ACE = [System.Security.AccessControl.FileSystemAccessRule]::new($Identity, $Permission, 'Allow')
        $ACL.AddAccessRule($ACE) | Out-Null
        $ACL | Set-Acl -Path $PrivateKeyPath
    }
}