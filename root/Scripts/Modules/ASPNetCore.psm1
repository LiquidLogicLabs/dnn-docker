function Install-DotNetCore {
    param(
        [string]$Version = "9.0"
    )

    # Install the ASP.NET Core Module
    Invoke-WebRequest -OutFile c:\dotnet-hosting-win.exe https://aka.ms/dotnet/$($Version)/dotnet-hosting-win.exe;
    $process = Start-Process -Filepath C:\dotnet-hosting-win.exe -ArgumentList  @('/install', '/q', '/norestart', 'OPT_NO_RUNTIME=1', 'OPT_NO_X86=1', 'OPT_NO_SHAREDFX=1') -Wait -PassThru 
    if ($process.ExitCode -ne 0) {
        exit $process.ExitCode;
    }
    Remove-Item -Force C:\dotnet-hosting-win.exe
}

Export-ModuleMember -Function Install-ASPNetCore