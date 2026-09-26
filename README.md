*This activity has been created as part of the 42 curriculum by abdothma.*

# Inception

## Description

This project is a Docker-based infrastructure for running a WordPress site with separate containers for the web server, the PHP application layer, and the database. The goal is to package the stack as independent services that can be built and started together with Docker Compose, while keeping the application and database data persistent on the host filesystem.

The repository contains three main services:

- `nginx`: serves the site over HTTPS on port `443`.
- `wordpress`: runs WordPress with PHP-FPM and installs the WordPress site at startup.
- `mariadb`: provides the MariaDB database used by WordPress.

The stack is organized around a Docker bridge network named `inception`, and the project uses two host bind-mounted directories for persistent data:

- `/home/abdothma/data/wordpress`
- `/home/abdothma/data/mariadb`

## Architecture

```text
Client
  |
  | HTTPS on port 443
  v
nginx -----------------------------> wordpress (PHP-FPM on 9000)
     \                                      |
      \_____________________________________| 
                      uses Docker network `inception`
                               |
                               v
                            mariadb (3306)
```

## Instructions

### Prerequisites

The project references the following tools and requirements in the repository itself:

- Docker
- `docker compose`
- GNU Make
- access to create the host directories used by the bind mounts

The Makefile assumes the host directories exist:

```sh
/home/abdothma/data/wordpress
/home/abdothma/data/mariadb
```

### Setup

The Compose file loads environment variables from `srcs/.env`, and the repository tracks an example file at `srcs/env_example`.

Create the runtime environment file from the example:

```sh
cp srcs/env_example srcs/.env
```

Then edit `srcs/.env` to match the environment used by your deployment.

The example file defines the following variables:

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

The WordPress startup script also uses `URL`, but that variable is not present in `srcs/env_example` and must be supplied by the environment that runs the stack.

### Build the project

From the repository root, build and start the stack with:

```sh
make run
```

This target does the following:

```make
mkdir -p /home/abdothma/data/wordpress
mkdir -p /home/abdothma/data/mariadb
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d
```

### Start and stop the project

Start the infrastructure:

```sh
make run
```

Stop it:

```sh
make stop
```

The stop target runs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down
```

Clean everything (containers, images, volumes, and host data):

```sh
make clean
```

This destructive target runs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down --volumes --rmi all
sudo rm -rf /home/abdothma/data
```

## Project Description

### How Docker is used

The project uses Docker Compose to define and run three services in a single stack. Each service is built from its own Dockerfile under `srcs/requirements`:

- `srcs/requirements/mariadb/Dockerfile`
- `srcs/requirements/nginx/Dockerfile`
- `srcs/requirements/wordpress/Dockerfile`

The root `srcs/docker-compose.yml` file defines service dependencies, networking, volumes, and restart behavior.

### Services in the project

| Service | Role | Notes |
| --- | --- | --- |
| `mariadb` | Database server | Runs MariaDB and initializes the database if needed. |
| `wordpress` | WordPress + PHP-FPM | Downloads WordPress core, creates `wp-config.php`, installs WordPress, and waits for MariaDB. |
| `nginx` | HTTPS reverse proxy | Serves HTTPS on port `443` and proxies PHP requests to `wordpress:9000`. |

### Main design choices

- Separate containers for each concern: database, application, and web server.
- A dedicated Docker bridge network named `inception` for service-to-service communication.
- Bind-mounted host directories instead of anonymous container storage for persistent data.
- Health checks to coordinate startup order.
- Self-signed TLS certificate generation in the NGINX image.

### Important configuration choices

The following configuration choices are directly visible in the repository:

- The project uses `driver: bridge` for the `inception` network.
- WordPress and MariaDB both use bind-mounted persistent host directories.
- NGINX listens on `443` and serves `root /var/www/html`.
- The nginx config forwards PHP files to `wordpress:9000`.
- The WordPress entrypoint creates the site and users if they are not already installed.
- The MariaDB init script creates the configured database and users only when `/var/lib/mysql/mysql` does not exist.

### Sources and resources used in the activity

The implementation is based on the files in this repository and the standard tooling or components they reference:

- Docker and Docker Compose
- NGINX
- MariaDB
- WordPress
- WP-CLI
- PHP 8.3 FPM and related modules
- Alpine Linux and Debian bookworm-slim base images

## Required comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker in this project |
| --- | --- | --- |
| Isolation | Full guest OS | Containerized services sharing the host kernel |
| Resource use | Higher overhead | Lower overhead for app services |
| Setup | Separate OS + runtime | Service images and Compose orchestration |

This project uses Docker because it is composed of separate services that need to run together with controlled networking and persistent storage, without requiring a full VM per component.

### Secrets vs Environment Variables

This project stores runtime values in `srcs/.env`, which is a plain environment file. The Compose configuration uses `env_file` to pass those values into the containers. This is useful for configuration, but environment variables are not a dedicated secret-management system. The repository also ignores `srcs/.env` and `secrets/` in `.gitignore`, which indicates that actual credentials should not be committed to the repo.

### Docker Network vs Host Network

The stack uses the `inception` network, a Docker bridge network. This allows containers to address each other by service name, such as `wordpress` and `mariadb`, without exposing those ports directly to the host. Only NGINX publishes host port `443:443`.

### Docker Volumes vs Bind Mounts

This project does not rely on Docker-managed anonymous volumes alone. It defines named volumes but configures them as bind mounts to fixed host directories:

- `/home/abdothma/data/wordpress`
- `/home/abdothma/data/mariadb`

This keeps the WordPress files and the MariaDB database data persistent on the host.

## Services

### NGINX

NGINX is built from `srcs/requirements/nginx/Dockerfile` and uses the config file at `srcs/requirements/nginx/config`.

Key behavior:

- listens for HTTPS on port `443`
- serves the site at `/var/www/html`
- terminates TLS with a certificate generated in the image
- routes PHP requests to `wordpress:9000`

### WordPress

WordPress is built from `srcs/requirements/wordpress/Dockerfile` and starts through `wp-entrypoint.sh`.

The entrypoint performs the following when needed:

- downloads WordPress core
- creates `wp-config.php`
- installs WordPress with WP-CLI
- creates users
- starts `php-fpm83` in the foreground

### MariaDB

MariaDB is built from `srcs/requirements/mariadb/Dockerfile` and initializes its database in `script.sh`.

Key behavior:

- creates the database and users when needed
- grants privileges on the WordPress database
- starts MariaDB with `--bind-address=0.0.0.0`
- exposes the container port `3306`

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

## Resources

### Official references

- Docker: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- NGINX: https://nginx.org/en/docs/
- WordPress: https://wordpress.org/documentation/
- WP-CLI: https://make.wordpress.org/cli/handbook/
- MariaDB: https://mariadb.com/docs/

### AI usage

AI was used in this documentation task to analyze the repository contents and turn the actual implementation into project documentation. The tasks performed were:

- reading the project files and deriving the current runtime architecture
- documenting the service responsibilities and startup flow
- summarizing the infrastructure design and required configuration
- writing the complementary README, user guide, and developer guide

## Security considerations

- `srcs/.env` is a runtime secret file and must not be committed.
- The NGINX certificate is self-signed and may trigger browser warnings.
- The project does not define Docker secrets; it relies on environment variables and host-level file protection.
- `make clean` removes persistent data from `/home/abdothma/data`, so it should be used carefully.

## Usage examples

Check container status:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env ps
```

Inspect logs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env logs -f
```

Stop the stack:

```sh
make stop
```

Remove the stack and data:

```sh
make clean
```

This README is intended to help someone unfamiliar with the project understand the current implementation without inventing undocumented behavior.
