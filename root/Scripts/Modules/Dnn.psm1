function Get-DnnByVersion {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Version,
        [string]$OutFile = 'C:\Defaults\DNN_Platform_Install.zip',
        [switch]$GenerateSha256
    )

    Write-Verbose "Downloading DNN Platform $Version"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $downloadUrl = "https://github.com/dnnsoftware/Dnn.Platform/releases/download/v$($Version)/DNN_Platform_$($Version)_Install.zip"
    Write-Verbose "Downloading DNN Platform: $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $OutFile

    if ($GenerateSha256.IsPresent) {
        # Generate SHA256 hash for downloaded file and save to file
        Write-Verbose "Generating SHA256 hash for $OutFile"
        $fileHash = Get-FileHash -Path $OutFile -Algorithm SHA256
        $fileHash.Hash | Out-File -FilePath "$($OutFile).sha256" -Verbose:$VerbosePreference
    }
}

function Install-DnnPlatform {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ArchiveFilePath = 'C:\Defaults\DNN_Platform_Install.zip',
        [string]$WebAppPath = 'C:\inetpub\wwwroot'
    )

    # Install DNN Platform
    Write-Verbose "Installing DNN Platform"
    Expand-Archive -Force -Path $ArchiveFilePath -DestinationPath $WebAppPath -WhatIf:$WhatIfPreference

    # Clean up
    # Write-Verbose "Cleaning up temp files"
    # Remove-Item $ArchiveFilePath -Force -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
    Set-IISFilePermissions -Path $WebAppPath -Verbose:$VerbosePreference

    Update-DnnWebConfig -WebAppPath $WebAppPath -GenerateNewMachineKey -Verbose:$VerbosePreference

    Write-Verbose "Done Initial Install"
}

function Update-DnnWebConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$WebAppPath = 'C:\inetpub\wwwroot',
        [switch]$GenerateNewMachineKey
    )

    Write-Verbose "Updating web.config (enabling support within docker)"
    [xml]$config = Get-Content -Path "$($WebAppPath)\web.config"
    
    #######################################################################################################
    # Update Web.config - Machien Key (for new installations)
    #######################################################################################################
    if ($GenerateNewMachineKey.IsPresent) {
        Write-Verbose "Generating new machine key"
        $validationKey = New-MachineKey -keyLength 64
        $decryptionKey = New-MachineKey -keyLength 32

        $machineKey = $config.configuration.'system.web'.machineKey
        if (-not $machineKey) {
            $machineKey = $config.CreateElement("machineKey")
            $config.configuration.'system.web'.AppendChild($machineKey)
        }
        
        $machineKey.SetAttribute("validationKey", $validationKey)
        $machineKey.SetAttribute("decryptionKey", $decryptionKey)
        $machineKey.SetAttribute("validation", "SHA1")
        $machineKey.SetAttribute("decryption", "AES")
    }

    #######################################################################################################
    # Update Web.config - Docker required changes
    #######################################################################################################
    Write-Verbose "Updating app settings: Disable AutoUpgrade"
    Set-AppSetting -config $config -key 'AutoUpgrade' -value 'false'

    # Update app settings
    Write-Verbose "Updating app settings to enable UsePortNumber"
    Set-AppSetting -config $config -key 'UsePortNumber' -value 'true'

    # Update httpRuntime settings
    Write-Verbose "Updating httpRuntime settings to disable FullyQualifiedRedirectUrl"
    $httpRuntimeKey = $config.configuration.'system.web'.httpRuntime
    if (-not $httpRuntimeKey) {
        $httpRuntimeKey = $config.CreateElement("httpRuntime")
        $config.configuration.'system.web'.AppendChild($httpRuntimeKey)
    }
    $httpRuntimeKey.SetAttribute("useFullyQualifiedRedirectUrl", 'false')

    # Save the updated web.config
    if ($PSCmdlet.ShouldProcess("$($WebAppPath)\web.config", "Saving updates to web.config")) {
        $config.Save("$($WebAppPath)\web.config")
    }
}

function Update-DnnConnectionString {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ConnectionString,
        [string]$WebAppPath = 'C:\inetpub\wwwroot'
    )

    Write-Verbose "Updating web.config (enabling support within docker)"
    [xml]$config = Get-Content -Path "$($WebAppPath)\web.config"

    # Update connection string in web.config
    $config.configuration.connectionStrings.GetElementsByTagName("add") `
        | Where-Object { $_.name -eq 'SiteSqlServer' } `
        | ForEach-Object { $_.connectionString = $connectionString }

    # Save the updated web.config
    if ($PSCmdlet.ShouldProcess("$($WebAppPath)\web.config", "Saving updates to web.config")) {
        $config.Save("$($WebAppPath)\web.config")
    }
}

#######################################################################################################
# Utility Functions - 
#######################################################################################################

# Function to set or update app settings in web.config
function Set-AppSetting {
    param (
        [xml]$config,
        [string]$key,
        [string]$value
    )
    $setting = $config.configuration.appSettings.add | Where-Object { $_.key -eq $key }
    if ($setting) {
        $setting.value = $value
    } else {
        $newSetting = $config.CreateElement("add")
        $newSetting.SetAttribute("key", $key)
        $newSetting.SetAttribute("value", $value)
        $config.configuration.appSettings.AppendChild($newSetting)
    }
}

# Function to generate a random machine key
function New-MachineKey {
    param (
        [Parameter(Mandatory=$true)]
        [int]$keyLength
    )
    # [string]$key = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count $keyLength | ForEach-Object {[char]$_})
    # return $key.ToUpper()

    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[] $keyLength
    $rng.GetBytes($bytes)
    
    $sb = New-Object System.Text.StringBuilder ($keyLength * 2)
    foreach ($byte in $bytes) {
        [void]$sb.Append($byte.ToString("X2"))
    }
    
    return $sb.ToString()    
}

#######################################################################################################
#######################################################################################################
# Exported Functions
#######################################################################################################
#######################################################################################################

Export-ModuleMember -Function Get-DnnByVersion
Export-ModuleMember -Function Install-DnnPlatform
Export-ModuleMember -Function Update-DnnWebConfig
Export-ModuleMember -Function Update-DnnConnectionString