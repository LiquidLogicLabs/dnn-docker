function Get-ServiceMonitor {
    param(
        [string]$OutFile = 'C:\ServiceMonitor.exe',
        [string]$Version = "2.0.1.10"
    )
    
    # Acquire ServiceMonitor
    $url = "https://dotnetbinaries.blob.core.windows.net/servicemonitor/$($Version)/ServiceMonitor.exe"
    Write-Verbose "Downloading ServiceMonitor: $url"
    Invoke-WebRequest -OutFile $OutFile -Uri $url
}

Export-ModuleMember -Function Get-ServiceMonitor