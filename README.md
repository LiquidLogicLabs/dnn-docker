# DNN Docker Container

This repository contains a Docker setup for running DotNetNuke (DNN) on a Windows Server Core container with ASP.NET 4.8.

This container create a default instance of DNN v9.13.7 if there is no content in the folder that is being mapped to c:/inetput/wwwroot.  if you map an EXISTING dnn webroot to that folder, it will use that instance (instead of creating a clean installation)

Note: If using an exiting webroot, make sure the DB_CONNECTION_STRING matches your existing connection string as the startup process will update the web.config 

## Features

- **DNN Version**: 9.13.7
- **ASP.NET Framework**: 4.8
- **Windows Server Core**: ltsc2019
- **SQL Server**: 2019 Express

## Sample compose.yaml

```yaml
services:
  web:
    image: liquidlogiclabs/dnn-docker:9.13.7
    container_name: dnn
    ports:
      - "8080:80"
    volumes:
      - ./data/web/:c:/inetpub/wwwroot/:rw
    environment:
      - ACCEPT_EULA=Y
      - DB_CONNECTION_STRING=Server=sql;Database=DotNetNuke;User Id=sa;Password=Password123;
      - DNN_VERSION=9.13.7
      - DEBUG=true
  
  sql:
    image: liquidlogiclabs/mssql-server-windows:2019-express
    container_name: sql
    ports:
      - "1433:1433"
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Password123
```

## Explination of Services

### Web

- **Image**: `liquidlogiclabs/dnn-docker:9.13.7`
- **Ports**: `8080:80`
- **Volumes**:
  - `./data/web/:c:/inetpub/wwwroot/:rw`
  - `./data/software/:c:/software/:rw`
- **Environment Variables**:
  - `ACCEPT_EULA=Y`
  - `DB_CONNECTION_STRING=Server=sql;Database=DotNetNuke;User Id=sa;Password=Password123;`
  - `DNN_VERSION=9.13.7`
  - `DEBUG=true`

### SQL (optional)

- **Image**: `liquidlogiclabs/mssql-server-windows:2019-express`
- **Ports**: `1433:1433`
- **Environment Variables**:
  - `ACCEPT_EULA=Y`
  - `SA_PASSWORD=Password123`
- **Notes**:
  - This is a custom build MSSQL image that supports attaching an existing database via ENV variables. It is possible to use ANY mssql server.

## Usage

1. Clone the repository.
2. Build the Docker image:
   ```sh
   docker-compose build
   ```
3. Start the containers:
   ```sh
   docker-compose up
   ```
4. Access the DNN site at `http://localhost:8080`.


## Notes

- Ensure Docker is configured to use Windows containers.
- Modify the `DB_CONNECTION_STRING` environment variable as needed for your setup.
