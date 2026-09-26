# Developer Documentation

## Overview

This document describes how the current Inception project is built, configured, and maintained. It is based on the files in this repository and should be treated as the implementation reference for the project as it exists now.

## Project structure

```text
.
├── .gitignore
├── Makefile
├── srcs
│   ├── docker-compose.yml
│   ├── env_example
│   └── requirements
│       ├── mariadb
│       │   ├── Dockerfile
│       │   └── script.sh
│       ├── nginx
│       │   ├── Dockerfile
│       │   └── config
│       └── wordpress
│           ├── Dockerfile
│           └── wp-entrypoint.sh
```

## Prerequisites

The repository itself assumes the following tools and access are available on the host:

- Docker
- `docker compose`
- GNU Make
- permission to create the data directories used by the bind mounts

The application paths referenced by the Compose file are:

- `/home/abdothma/data/wordpress`
- `/home/abdothma/data/mariadb`

## Environment setup

The runtime environment file is:

```text
srcs/.env
```

The repository includes a template at `srcs/env_example`. Create the real file from it:

```sh
cp srcs/env_example srcs/.env
```

The project uses the following variables in the current implementation:

```env
DB_NAME=wordpress
DB_USER=me
DB_ADMIN=boss
DB_USER_PASSWORD=982512324565
DB_ADMIN_PASSWORD=1209384907
WORDPRESS_USER=me
WORDPRESS_ADMIN=john
WORDPRESS_PASSWORD=1234754434
```

The WordPress entrypoint also uses `URL` during installation, but that variable is not included in the tracked example file and must be added to the runtime `.env` file for the stack to initialize correctly.

The Git repository ignores the real environment file and the `secrets/` directory:

```gitignore
srcs/.env
secrets/
```

## Makefile and project lifecycle

The Makefile defines the three main targets:

```makefile
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
```

Usage:

```sh
make run
make stop
make clean
```

## Docker Compose structure

The Compose file is located at:

```text
srcs/docker-compose.yml
```

It defines the following services:

| Service | Build context | Ports / exposure | Networks | Data |
| --- | --- | --- | --- | --- |
| `mariadb` | `./requirements/mariadb` | internal `3306` | `inception` | `mariadb_volume` |
| `nginx` | `./requirements/nginx` | host `443:443` | `inception` | `wordpress_volume` |
| `wordpress` | `./requirements/wordpress` | internal `9000` | `inception` | `wordpress_volume` |

The network and volumes are defined as:

```yaml
networks:
  inception:
    driver: bridge

volumes:
  wordpress_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/abdothma/data/wordpress

  mariadb_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/abdothma/data/mariadb
```

## Service startup order and health checks

The stack uses dependency-based startup:

- `mariadb` has a healthcheck using `mariadb-admin ping --silent`
- `wordpress` has a healthcheck using `ls /ready`
- `nginx` depends on WordPress being healthy

This is visible in the Compose file:

```yaml
depends_on:
  mariadb:
    condition: service_healthy
```

and:

```yaml
depends_on:
  wordpress:
    condition: service_healthy
```

## MariaDB service

### Dockerfile

`srcs/requirements/mariadb/Dockerfile` is based on `debian:bookworm-slim`:

```dockerfile
FROM debian:bookworm-slim

RUN apt update && apt install -y mariadb-server

RUN rm -rf /var/lib/mysql/*

EXPOSE 3306

COPY script.sh /script.sh

ENTRYPOINT ["bash", "/script.sh"]
```

### Database initialization script

`srcs/requirements/mariadb/script.sh` does the following:

```sh
set -e

mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mariadb-install-db --user=mysql

	mariadbd --user=mysql &

	for i in $(seq 1 30); do
		mariadb-admin ping --silent && break
		sleep 1
	done

	mariadb <<EOF
CREATE DATABASE `${DB_NAME}`;
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
CREATE USER '${DB_ADMIN}'@'%' IDENTIFIED BY '${DB_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON `${DB_NAME}`.* TO '${DB_USER}'@'%';
GRANT ALL PRIVILEGES ON `${DB_NAME}`.* TO '${DB_ADMIN}'@'%';
FLUSH PRIVILEGES;
EOF
	mysqladmin -u root shutdown
	wait $!
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0
```

This script initializes MariaDB only if `/var/lib/mysql/mysql` does not already exist. After setup, the database runs with `--bind-address=0.0.0.0`.

### Persistent data

The MariaDB persistent volume is mounted at:

```text
/home/abdothma/data/mariadb
```

and inside the container at:

```text
/var/lib/mysql
```

This is where the WordPress database is stored.

## WordPress service

### Dockerfile

`srcs/requirements/wordpress/Dockerfile` is based on `alpine:3.23` and installs PHP, PHP-FPM, required PHP extensions, MariaDB client tools, and WP-CLI.

Key excerpt:

```dockerfile
FROM alpine:3.23

RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-pdo \
    php83-pdo_mysql \
    php83-json \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-mbstring \
    php83-openssl \
    php83-xml \
    php83-xmlreader \
    php83-xmlwriter \
    php83-simplexml \
    php83-zip \
    php83-zlib \
    php83-gd \
    php83-intl \
    php83-opcache \
    php83-phar \
    php83-session \
    php83-tokenizer \
    php83-iconv \
    php83-posix \
    mariadb-client \
    curl \
    bash \
    && ln -sf /usr/bin/php83 /usr/bin/php
```

It also downloads WP-CLI from the official build URL and configures PHP-FPM to listen on port `9000`.

### Entrypoint behavior

`srcs/requirements/wordpress/wp-entrypoint.sh` is the main startup script. It does the following:

```sh
#!/bin/bash
set -e

cd /var/www/html

if [ ! -f wp-load.php ]; then
  echo "wordpress: downloading core..."
  wp core download --allow-root
fi

if [ ! -f wp-config.php ]; then
  echo "wordpress: writing wp-config.php..."
  wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_USER_PASSWORD" \
    --dbhost="mariadb" \
    --skip-check \
    --allow-root
fi

if ! wp core is-installed --allow-root; then
  echo "wordpress: running core install..."
  wp core install \
    --url="$URL" \
    --title="inception" \
    --admin_user="$WORDPRESS_ADMIN" \
    --admin_password="$WORDPRESS_PASSWORD" \
    --admin_email="${WORDPRESS_ADMIN}@gmail.com" \
    --skip-email \
    --allow-root

  echo "wordpress: creating second (non-admin) user..."
  wp user create "$WORDPRESS_USER" "${WORDPRESS_USER}@gmail.com" \
    --role=author \
    --user_pass="$WORDPRESS_PASSWORD" \
    --allow-root
fi

chown -R nobody:nobody /var/www/html

touch /ready
exec php-fpm83 -F
```

Important notes:

- The site is installed only if WordPress is not already installed.
- The WordPress files are persisted in the bind-mounted volume.
- The healthcheck uses `/ready`, which is created after the setup is complete.

### WordPress persistent data

The WordPress site is stored at:

```text
/home/abdothma/data/wordpress
```

and mounted inside the container at:

```text
/var/www/html
```

This covers the WordPress core files and the generated `wp-config.php`.

## NGINX service

### Dockerfile

`srcs/requirements/nginx/Dockerfile` uses `alpine:3.23` and installs `nginx` and `openssl`:

```dockerfile
FROM alpine:3.23

RUN apk add nginx openssl

RUN mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=JO/ST=Irbid/L=Irbid/O=42/CN=abdothma.42.fr"

RUN sed -i 's/TLSv1.1 //' /etc/nginx/nginx.conf

COPY config /etc/nginx/http.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

### NGINX config

`srcs/requirements/nginx/config` contains the server block:

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name abdothma.42.fr;

    ssl_certificate /etc/nginx/ssl/inception.crt;
    ssl_certificate_key /etc/nginx/ssl/inception.key;

    root /var/www/html;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

The file forwards PHP to the `wordpress` service over the Docker network on port `9000`.

## Common development commands

Inspect status:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env ps
```

View logs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env logs
```

Follow logs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env logs -f
```

Rebuild services without deleting data:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d --build
```

Stop the services:

```sh
make stop
```

Clean the stack and delete persistent data:

```sh
make clean
```

## Troubleshooting and maintenance guidance

### Services do not start

Verify the following:

- `srcs/.env` exists and includes all required variables
- `URL` exists for WordPress installation
- the host directories can be created and written to
- Docker is running correctly

### WordPress is not installed

Check whether the persisted WordPress files already exist in `/home/abdothma/data/wordpress`. The entrypoint only installs WordPress if it is not already installed.

### MariaDB errors

Check the MariaDB container logs. The initialization script creates the database and users only once; if the database has already been created, the script will not reinitialize it.

### NGINX access issues

Confirm:

- the `nginx` container is running
- port `443` is open on the host
- the requested hostname resolves to the host
- the self-signed certificate is accepted or expected

## Security and implementation notes

- Real values must stay in `srcs/.env` and must not be committed.
- The project does not use Docker secrets; it uses environment variables.
- TLS is self-signed and intended for local or project-specific use.
- `make clean` permanently removes the persistent WordPress and MariaDB directories.

This document intentionally reflects the implementation currently present in the repository and avoids describing features or behavior that are not in the project files.
