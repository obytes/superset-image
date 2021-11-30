help:
	@echo "docker-compose commands:"
	@echo "    make down: 		       Removes all docker containers running"
	@echo "    make down_init: 		   Removes all docker containers running including the init service"
	@echo "    make up: 		       Up all services - Starts all services"
	@echo "    make bash: 		       Bash into application container"
	@echo "    make ps:			       list containers/services"
	@echo "	   make restart:           restart (removes all services and restart them -- without rebuilding)"
	@echo "	   make build:		       build (usually, requires to build when changes happen to the Dockerfile or docker-compose.yml)"


down:
	docker compose down && docker compose rm -f

down_init:
	docker compose --file docker-compose-init.yml down && docker-compose rm -f

rm_all:
	docker rm -f $(docker ps -aq)

up:
	docker compose up -d

up_init:
	docker compose --file docker-compose-init.yml up -d

ps:
	docker compose ps

restart:
	make rm && make up

build:
	docker compose build

build_init:
	docker compose --file docker-compose-init.yml build

bash:
	docker compose run --rm superset bash