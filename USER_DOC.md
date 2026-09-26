# User Documentation

## Overview

This project runs a WordPress website in Docker using three services:

| Service | Purpose |
| --- | --- |
| `nginx` | Receives HTTPS traffic on port `443` and serves the WordPress site. |
| `wordpress` | Runs WordPress with PHP-FPM and performs the WordPress installation. |
| `mariadb` | Stores the WordPress database. |

The services communicate over the Docker bridge network called `inception`.

## Start the activity

From the project root, create the environment file if needed:

```sh
cp srcs/env_example srcs/.env
```

Then edit `srcs/.env` so it contains the required values for your environment, including the `URL` used by the WordPress installation logic.

Start the stack:

```sh
make run
```

This command creates the required host directories and starts the services in the background with Docker Compose.

## Stop the activity

Stop the stack without deleting the persistent data:

```sh
make stop
```

This runs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down
```

## Restart the activity

To restart the stack after it has been stopped:

```sh
make run
```

## Access the website

The project configures NGINX with the server name:

```text
abdothma.42.fr
```

The site is served over HTTPS on port `443` and the TLS certificate is self-signed. The repository does not define a local hostname setup, so the address must resolve to the host where the containers are running.

Expected access pattern:

```text
https://abdothma.42.fr
```

## Access the WordPress administration panel

The WordPress admin area is typically accessed at:

```text
https://abdothma.42.fr/wp-admin
```

Use the administrator username and password defined in `srcs/.env` via the variables:

- `WORDPRESS_ADMIN`
- `WORDPRESS_PASSWORD`

Do not expose or publish real values in documentation.

## Where credentials are stored

The runtime credentials are stored in the untracked file:

```text
srcs/.env
```

The repository includes an example file at `srcs/env_example`, but the real values must be placed in `.env` and kept out of version control.

The variables used by the stack are:

- `DB_NAME`
- `DB_USER`
- `DB_USER_PASSWORD`
- `DB_ADMIN`
- `DB_ADMIN_PASSWORD`
- `WORDPRESS_USER`
- `WORDPRESS_ADMIN`
- `WORDPRESS_PASSWORD`
- `URL`

## Check whether services are running correctly

List the running Docker services:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env ps
```

Inspect logs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env logs
```

To follow logs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env logs -f
```

The Compose file defines health checks for `mariadb` and `wordpress`:

- MariaDB healthcheck: `mariadb-admin ping --silent`
- WordPress healthcheck: checks for `/ready`

## Inspect container status

Use the Docker Compose status command:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env ps
```

If a container is not healthy, inspect the logs and review the corresponding environment file entries.

## Troubleshooting basic problems

### The site is not reachable

Check the following:

1. NGINX is running.
2. Port `443` is available on the host.
3. The hostname `abdothma.42.fr` resolves to the Docker host.
4. The browser accepts the self-signed certificate warning.

### WordPress is not ready

The WordPress container waits for MariaDB health before completing its initialization. Check the container logs and ensure the database service is healthy first.

### Credentials no longer work

The project persists data on the host. If the WordPress site or MariaDB database was already initialized before configuration changes, the old site and database state may remain in place. If the data needs to be reset, use the project cleanup command described below.

## Cleanup

To remove the stack and delete the persistent host data:

```sh
make clean
```

This command runs:

```sh
docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down --volumes --rmi all
sudo rm -rf /home/abdothma/data
```

Use this only when you intentionally want to remove the persistent site and database data.

## Important administrator information

Persistent project data is stored here:

- `/home/abdothma/data/wordpress`
- `/home/abdothma/data/mariadb`

These paths are configured as bind mounts in the Compose file. The stack writes WordPress files and the MariaDB database to these directories.

The project uses a self-signed certificate generated during image build. Administrators should expect browser warnings and plan for a proper certificate or DNS/name resolution setup if the site must be accessed in a production-like environment.

The repository does not define a password manager, Kubernetes secret store, or advanced secret-management workflow. For this project, the runtime credentials are in the host `srcs/.env` file.
