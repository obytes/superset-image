<img src="https://github.com/apache/superset/raw/master/superset-frontend/src/assets/branding/superset-logo-horiz-apache.png" alt="Superset" width="500"/>
A modern, enterprise-ready business intelligence web application.

### Overview 
This Docker image is an extended image from the official [DockerHub](https://hub.docker.com/r/apache/superset) with additional requirements such as snowflake-sqlalchemy, gunicron and gevent

### Running the docker stack local
 
 - For running the stack for the first time we are going to use the docker-compose-init.yml file as it has the init_service container to create the required initial user and setting up the database `superset db update`
     - `make build_init`
     - `make up_init` In this stack the superset-app is using the Flask development web server which is not intended to be used in production
 - To run the stack without the init_service, no need to re-initialize
    - `make build`
    - `make up` In this stack the superset-app is using the gunicorn web server  with gevent worker-class `production use` 
    

### Environment file
All the containers in docker-compose stack using the docker-compose.local.env file, you can customize the environments variables   