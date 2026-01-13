## Understanding the services

This project runs on Docker and includes the following services: 
- **Nginx**:  Web server with TLS/SSL support
- **WordPress**: Content management system
- **MariaDB**: Database service
- (añade otros servicios si los tienes)

All services run in isolated containers and communicate through a Docker network.

## Start/stop


The project can be easily started by running the command `make`
You can choose to use the command `docker compose build` and `docker compose up` to run the program.

## Access the website and administrator panel

Once the containers are built, you can access the web by either typing `(42 login).42.fr` or localhost on the browser. In my case smarquez.42.fr.


To access the admin panel just type `(42 login).42.fr/admin` or localhost/admin

Credentials are in the .env file.

## Locate and manage credentials

For security purposes, the credentials are hidden in the .env file. The env file is stored locally and only exposed during evaluation.

I have decided to include an example env file with mock credentials for anyone to copy and change with the correct information.


## Check that the services are running correctly

A simple command to check everything is running is to use `docker ps` once the containers are working.

Other way of checking is to use `docker logs (container name)` to check for a specific container. Example: `docker logs mariadb`