Function Write-ErrorMessage {
    [CmdletBinding()]
    Param(
        $ExceptionType,

        $Message,

        [ValidateSet("NotSpecified",
            "OpenError",
            "CloseError",
            "DeviceError",
            "DeadlockDetected",
            "InvalidArgument",
            "InvalidData",
            "InvalidOperation",
            "InvalidResult",
            "InvalidType",
            "MetadataError",
            "NotImplemented",
            "NotInstalled",
            "ObjectNotFound",
            "OperationStopped",
            "OperationTimeout",
            "SyntaxError",
            "ParserError",
            "PermissionDenied",
            "ResourceBusy",
            "ResourceExists",
            "ResourceUnavailable",
            "ReadError",
            "WriteError",
            "FromStdErr",
            "SecurityError",
            "ProtocolError",
            "ConnectionError",
            "AuthenticationError",
            "LimitsExceeded",
            "QuotaExceeded",
            "NotEnabled"
        )]
        $Category,

        $CategoryActivity,

        $TargetType,

        [System.String]
        $Source,

        [Parameter(ParameterSetName = 'Exception')]
        $Exception,

        $ErrorId
    )

    if ($PSCmdlet.ParameterSetName -eq 'Exception') {
        $ErrorRecordException = (New-Object -TypeName $ExceptionType)::new($Message, $Exception)
    } else {
        $ErrorRecordException = (New-Object -TypeName $ExceptionType)::new($Message)
    }

    $ErrorRecordException.Source = $Source
    #$ErrorRecordException.HelpLink = 

    $RecordType = [System.Management.Automation.ErrorRecord]
    $ErrorRecord = $RecordType::new($ErrorRecordException, $ErrorId, $Category, $Source)
    $ErrorRecord.CategoryInfo.Activity = $CategoryActivity
    $ErrorRecord.CategoryInfo.TargetType = $TargetType
    
    $RecordType.InvokeMember('SetInvocationInfo', 'Instance,NonPublic,InvokeMethod', $null, $ErrorRecord, $MyInvocation)
    $PSCmdlet.ThrowTerminatingError($ErrorRecord)

    <#
    $ErrorRecordType = [System.Management.Automation.ErrorRecord]
        
    $ErrorRecordException = [System.NotSupportedException]::new("The PrivateKey was not found.")
    $ErrorRecordException.Source = $Certificate.Thumbprint
    #$ErrorRecordException.HelpLink = 

    $ErrorRecord = $ErrorRecordType::new($ErrorRecordException, 'ErrorId', 'InvalidResult', $Certificate.Thumbprint)
    $ErrorRecord.CategoryInfo.Activity = "HasPrivateKey"
    $ErrorRecord.CategoryInfo.TargetType = "System.Boolean"
    $ErrorRecordType.InvokeMember('SetInvocationInfo', 'Instance, NonPublic, InvokeMethod', $null, $ErrorRecord, $MyInvocation)
        
    $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    #>
    
    <#
    $Exception = $PSItem.Exception
    $ErrorRecordType = [System.Management.Automation.ErrorRecord]

    $ErrorRecordException = [System.IO.FileNotFoundException]::new("Unable to obtain the PrivateKey File", $Exception)
    #$ErrorRecordException.Source = $Certificate.Thumbprint
    #$ErrorRecordException.HelpLink = 

    $ErrorRecord = $ErrorRecordType::new($ErrorRecordException, 'ErrorId', 'InvalidResult', $Certificate.Thumbprint)
    $ErrorRecord.CategoryInfo.Activity = "PrivateKey.Key.UniqueName"
    $ErrorRecord.CategoryInfo.TargetType = "System.String"
    $ErrorRecordType.InvokeMember('SetInvocationInfo', 'Instance, NonPublic, InvokeMethod', $null, $ErrorRecord, $MyInvocation)
        
    $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    #>
}