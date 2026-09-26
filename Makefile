COMPOSE = docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env

run:
	mkdir -p /home/abdothma/wordpress
	mkdir -p /home/abdothma/mariadb
	$(COMPOSE) up -d

stop:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --volumes --rmi all
	sudo rm -rf /home/abdothma/wordpress
	sudo rm -rf /home/abdothma/mariadb
