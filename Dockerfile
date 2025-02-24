# this Dockerfile borrows ideas from https://github.com/Microsoft/mssql-docker/blob/1efc4cf9b78fa5fccea682f26067189660af85c8/windows/mssql-server-windows-express/dockerfile
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-20250114-windowsservercore-ltsc2019   
#FROM mcr.microsoft.com/dotnet/aspnet:9.0.1-windowsservercore-ltsc2022

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ARG DNN_VERSION=9.13.7
ARG DOWNLOAD_DNN=true

ENV DB_CONNECTION_STRING _
ENV DOWNLOAD_DNN=$DOWNLOAD_DNN

COPY root/ /

RUN /Scripts/Install.ps1

WORKDIR "C:\inetpub\wwwroot"

VOLUME "C:\inetpub\wwwroot" 

EXPOSE 8080

ENTRYPOINT [ "powershell", "-NoProfile", "-Command", "/Scripts/Start.ps1 -connectionString $env:DB_CONNECTION_STRING -Verbose" ]