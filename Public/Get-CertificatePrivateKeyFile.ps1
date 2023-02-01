function Get-CertificatePrivateKeyFile {
    <#
    .SYNOPSIS
    Retrieves the location for the certificate private key file.
    .PARAMETER Certificate
    The certificate object. Must reside in the LocalUser store or LocalMachine store.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $PrivateKeyPath = "$Env:AllUsersProfile\Microsoft\Crypto\RSA\MachineKeys", "$env:APPDATA\Microsoft\Crypto\Keys", "$env:APPDATA\Microsoft\Crypto\RSA"

    if (!$Certificate.HasPrivateKey) {
        try {
            Write-ErrorMessage -ExceptionType "System.NotSupportedException" `
                -Message "The PrivateKey was not found." `
                -Category "InvalidResult" `
                -CategoryActivity "HasPrivateKey" `
                -TargetType "Systme.Boolean" `
                -Source $Certificate.Thumbprint `
                -ErrorId "MissingPrivateKey"
        }
        Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    if (!$Certificate.PrivateKey.Key.UniqueName -and !$Certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName) {
        try {
            Write-ErrorMessage -ExceptionType "System.Management.Automation.GetValueException" `
                -Message "The UniqueName was not found" `
                -Category "InvalidResult" `
                -CategoryActivity "PrivateKey.Key.UniqueName" `
                -TargetType "Systme.String" `
                -Source $Certificate.Thumbprint `
                -ErrorId "MissingKeyUniqueName"
        }
        Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    if ($PSVersionTable.PSVersion.Major -gt 5) {
        $Filter = $Certificate.PrivateKey.Key.UniqueName
    } else {
        $Filter = $Certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    }

    $PrivateKeyFile = (Get-ChildItem -Path $PrivateKeyPath -Filter $Filter -Recurse).FullName

    if (!(Test-Path -Path $PrivateKeyFile -ErrorAction SilentlyContinue)) {
        try {
            Write-ErrorMessage -ExceptionType "System.IO.FileNotFoundException" `
                -Message "The PrivateKey File was not found." `
                -Category "ObjectNotFound" `
                -CategoryActivity "HasPrivateKey" `
                -TargetType "Systme.String" `
                -Source $Certificate.Thumbprint `
                -ErrorId "FileNotFound"
        }
        Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    return $PrivateKeyFile
}