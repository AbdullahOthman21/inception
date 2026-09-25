.PHONY: run stop clean fclean

COMPOSE = docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env
DATA_PATH = /home/me/data

run:
	mkdir -p "$(DATA_PATH)/wordpress" "$(DATA_PATH)/mariadb"
	$(COMPOSE) up -d

stop:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down --remove-orphans --volumes --rmi all
	sudo rm -rf "$(DATA_PATH)/wordpress" "$(DATA_PATH)/mariadb"
