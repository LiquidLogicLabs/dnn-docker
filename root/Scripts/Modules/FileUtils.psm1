function Test-FileAgainstSha256 {
    param(
        [string]$FilePath,
        [string]$Sha256FilePath
    )

    if (Test-Path -Path $FilePath) {
        Write-Verbose "Validating SHA256 hash for $FilePath against contents in '$Sha256FilePath'"
        # validate sha256 hash
        $expectedHash = Get-Content -Path $Sha256FilePath
        $actualHash = Get-FileHash -Path $FilePath

        if ($($expectedHash) -ne $($actualHash.Hash)) {
            Write-Verbose "ERROR: SHA256 hash mismatch for file '$FilePath'"
            Write-Verbose "Expected: $expectedHash"
            Write-Verbose "Actual: $actualHash"

            return $false
        }
    }

    return $true

}

function Set-IISFilePermissions {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Path = 'C:\inetpub\wwwroot'
    )

    # Set permissions
    Write-Verbose "Setting permissions on $Path"
    if ($PSCmdlet.ShouldProcess("Setting permissions on $Path", "Setting permissions on $Path")) {
        &icacls $Path /grant 'IIS AppPool\DefaultAppPool:(OI)(CI)M' /T | Out-Null
    }
}


Export-ModuleMember -Function Test-FileAgainstSha256
Export-ModuleMember -Function Set-IISFilePermissions