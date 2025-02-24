# Ensure required directories exist
if (-not (Test-Path C:\inetpub\wwwroot)) { 
    New-Item -Path C:\inetpub\wwwroot -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path C:\Software)) { 
    New-Item -Path C:\Software -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path C:\Defaults)) { 
    New-Item -Path C:\Defaults -ItemType Directory -Force | Out-Null
}

Import-Module /Scripts/Modules/Dnn.psm1

if ($env:DOWNLOAD_DNN -eq 'true' -or $env:DOWNLOAD_DNN -eq 'True' -or $env:DOWNLOAD_DNN -eq '1') {
    Write-Host "Downloading DNN Platform $env:DNN_VERSION"
    Get-DnnByVersion -Version $env:DNN_VERSION -OutFile C:\Defaults\DNN_Platform_Install.zip -GenerateSha256 -Verbose:$true
}

Import-Module c:\Scripts\Modules\ServiceMonitor.psm1
Import-Module c:\Scripts\Modules\ASPNetCore.psm1
Import-Module c:\Scripts\Modules\FileUtils.psm1

Get-ServiceMonitor
#Install-DotNetCore
Set-IISFilePermissions

# DNS workaround, from https://github.com/docker/for-win/issues/500#issuecomment-289373352
Write-Host "Applying DNS workaround"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord

Remove-Item -Force -Recurse $Env:Temp\*
