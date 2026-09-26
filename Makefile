COMPOSE = docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env

run:
	mkdir -p /home/abdothma/data/wordpress
	mkdir -p /home/abdothma/data/mariadb
	$(COMPOSE) up -d

stop:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --volumes --rmi all
	sudo rm -rf /home/abdothma/data
