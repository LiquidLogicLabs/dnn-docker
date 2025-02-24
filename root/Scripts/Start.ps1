# This script borrows ideas from https://github.com/Microsoft/mssql-docker/blob/1efc4cf9b78fa5fccea682f26067189660af85c8/windows/mssql-server-windows-express/start.ps1

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$connectionString
)

if ($env:DEBUG -eq 'true' -or $env:DEBUG -eq 'True' -or $env:DEBUG -eq '1') {
    $VerbosePreference = $true
} else {
    $VerbosePreference = $false
}

#######################################################################################################
# Install DNN Platform (if not already installed)
#######################################################################################################
Import-Module c:\Scripts\Modules\Dnn.psm1
Import-Module c:\Scripts\Modules\FileUtils.psm1

$webAppRoot = 'C:\inetpub\wwwroot'
$dnnPlatformArchive = 'C:\Software\DNN_Platform_Install.zip'
$dnnPlatformCachedArchive = 'C:\Defaults\DNN_Platform_Install.zip'

# Create required directories
if (-Not (Test-Path -Path $webAppRoot)) { New-Item -Path $webAppRoot -ItemType Directory -Force | Out-Null }

# Download and install DNN Platform if wwwroot is empty
if ((Get-ChildItem -Path $webAppRoot | Measure-Object).Count -eq 0) { 

    # Do we have a cached copy of DNN Platform
    if (Test-Path -Path $dnnPlatformCachedArchive) {
        Write-Host "Using cached copy of DNN Platform"
        Copy-Item -Path $dnnPlatformCachedArchive -Destination $dnnPlatformArchive -Force -Verbose:$VerbosePreference
        Copy-Item -Path "$($dnnPlatformCachedArchive).sha256" -Destination "$($dnnPlatformArchive).sha256" -Force -Verbose:$VerbosePreference
    }

    if (-Not (Test-Path -Path $dnnPlatformArchive)) { 
        # Download DNN Platform
        Write-Host "Downloading DNN Platform $env:DNN_VERSION"
        Get-DnnByVersion -Version $env:DNN_VERSION -OutFile $dnnPlatformArchive -GenerateSha256 -Verbose:$VerbosePreference
    } else {
        Write-Host "DNN Platform already downloaded. Skipping download."
    }

    if (-Not (Test-FileAgainstSha256 -FilePath $dnnPlatformArchive -Sha256FilePath "$($dnnPlatformArchive).sha256" -Verbose:$VerbosePreference)) {
        Write-Host "ERROR: Mismatch between archive and exptected SHA256 hash."

        exit 1
    } else {
        Write-Host "Validated DNN Platform Archive"
    }

    Write-Host "Installing DNN Platform Version: $env:DNN_VERSION"
    Install-DnnPlatform -ArchiveFilePath $dnnPlatformArchive -WebAppPath $webAppRoot -Verbose:$VerbosePreference

    # Clean up
    # Write-Verbose "Cleaning up temp files"
    # Remove-Item $dnnPlatformArchive -Force -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference

    Write-Host "Done Initial Install"
}


#######################################################################################################
# Update Web.config - Runtime configuration changes
#######################################################################################################

# Ensure a connection string is provided
if ($connectionString -eq '_') {
    Write-Verbose 'ERROR: You must provide a connection string.'
    Write-Host 'Set the environment variable connection_string to a connection string for a DNN database.'
    exit 1
}

Write-Host "Updating DNN Connection String"
Update-DnnConnectionString -ConnectionString $connectionString -Verbose:$VerbosePreference

# Start IIS
Write-Host "Starting and Monitoring IIS"
c:\ServiceMonitor.exe w3svc