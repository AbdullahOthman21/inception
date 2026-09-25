# User Documentation — Inception

## Overview

The Inception stack is a containerized web application that provides:

- **WordPress Website**: A fully functional WordPress blog and content management system
- **Nginx Web Server**: Secure HTTPS frontend that serves web requests
- **MariaDB Database**: Backend database that stores all website content and configuration

All services run in isolated Docker containers and communicate securely with each other through a private network.

## Understanding the Services

### Nginx (Web Server)
Handles incoming web requests on port 443 (HTTPS only). It acts as a reverse proxy, forwarding PHP requests to the WordPress container and serving static files.

### WordPress (Application)
Runs PHP-FPM, which processes dynamic website content. It connects to the MariaDB database to retrieve and store all website data. This is where your website content lives.

### MariaDB (Database)
Stores all WordPress data including posts, pages, users, settings, and media metadata. Data persists on your host machine even when containers stop.

---

## Starting and Stopping the Stack

### Start the Services

```bash
make run
```

This command will:
1. Create necessary data directories
2. Build Docker images (first time only)
3. Start all containers
4. Initialize the database (first time only)

**Expected output**: Containers start silently in the background. Check their status with:
```bash
docker compose -f srcs/docker-compose.yml ps
```

### Stop the Services

```bash
make stop
```

This command stops all running containers while preserving all data. You can restart them later without losing anything.

### Clean Up (Remove Containers)

```bash
make clean
```

Stops and removes all containers and networks, but keeps all data intact. Use this if you need to reset the Docker environment.

### Full Reset (Delete Everything)

```bash
make fclean
```

**Warning**: This removes everything including containers, images, networks, volumes, and all stored data. Only use this if you want a complete fresh start.

---

## Accessing the Website and Administration Panel

### Prerequisites

Add the website domain to your local hosts file:

```bash
sudo sh -c 'echo "127.0.0.1 abdothma.42.fr" >> /etc/hosts'
```

### Access the Website

Open your browser and navigate to:

```
https://abdothma.42.fr
```

**Note**: Your browser may show a security warning about the SSL certificate. This is normal for self-signed certificates. Click "Proceed" or "Advanced" and continue.

### Access the WordPress Admin Panel

Navigate to:

```
https://abdothma.42.fr/wp-admin
```

Log in using the WordPress credentials from your environment configuration (see **Locating and Managing Credentials** section below).

---

## Locating and Managing Credentials

### Configuration File

All credentials and configuration values are stored in:

```
srcs/.env
```

This file contains:
- WordPress database name and user credentials
- MariaDB root password
- WordPress admin username and password
- Domain name configuration

### Common Credentials

Look for these variables in `srcs/.env`:

| Variable | Purpose |
|----------|---------|
| `DB_NAME` | Database name |
| `DB_USER` | WordPress database user |
| `DB_PASSWORD` | Database user password |
| `DB_ROOT_PASSWORD` | MariaDB root password |
| `WP_ADMIN_USER` | WordPress admin username |
| `WP_ADMIN_PASSWORD` | WordPress admin password |
| `WP_ADMIN_EMAIL` | WordPress admin email |
| `DOMAIN_NAME` | Website domain |

### Changing Credentials

**Important**: Change credentials only before running `make run` for the first time. To change credentials after initial setup:

1. Stop the stack: `make stop`
2. Update values in `srcs/.env`
3. Run full reset: `make fclean`
4. Start fresh: `make run`

---

## Checking Service Health

### View Running Containers

```bash
docker compose -f srcs/docker-compose.yml ps
```

Expected output shows three containers (`nginx`, `wordpress`, `mariadb`) all in a "running" state.

### Check Container Logs

View logs from all services:

```bash
docker compose -f srcs/docker-compose.yml logs
```

View logs from a specific service:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### Verify Database Connectivity

Access the database container and test the connection:

```bash
docker exec mariadb mariadb-admin ping --silent
```

Expected output: No output (success) or "mysqld is alive"

### Check Website Response

Test if the website is responding:

```bash
curl -k https://abdothma.42.fr
```

The `-k` flag ignores SSL certificate warnings.

### View Container Statistics

Monitor CPU, memory, and network usage:

```bash
docker stats
```

---

## Troubleshooting

### Services Won't Start

1. Check if Docker and Docker Compose are installed:
   ```bash
   docker --version
   docker compose --version
   ```

2. Verify data directories exist:
   ```bash
   ls -la /home/me/data/
   ```

3. Check container logs for errors:
   ```bash
   docker compose -f srcs/docker-compose.yml logs
   ```

### Website Shows Connection Error

1. Verify containers are running: `docker ps`
2. Check if the domain is in your hosts file: `grep abdothma.42.fr /etc/hosts`
3. Try a different browser or clear your browser cache
4. Restart the stack: `make stop` and `make run`

### Database Connection Fails

1. Check MariaDB container logs: `docker compose -f srcs/docker-compose.yml logs mariadb`
2. Verify database credentials in `srcs/.env`
3. Ensure enough disk space is available: `df -h`

### Lost Admin Access

1. Stop the stack: `make stop`
2. Update credentials in `srcs/.env`
3. Delete the WordPress data directory: `sudo rm -rf /home/me/data/wordpress`
4. Start fresh: `make run` (WordPress will reinstall)

---

## Data Storage and Persistence

Your website data is stored in two locations on your host machine:

### WordPress Files
```
/home/me/data/wordpress/
```
Contains WordPress configuration, plugins, themes, and uploaded media.

### Database Files
```
/home/me/data/mariadb/
```
Contains the MariaDB database files with all posts, pages, users, and settings.

Both directories persist when containers stop or restart, ensuring your data is never lost.

---

## Quick Command Reference

| Task | Command |
|------|---------|
| Start stack | `make run` |
| Stop stack | `make stop` |
| View running containers | `docker compose -f srcs/docker-compose.yml ps` |
| View all logs | `docker compose -f srcs/docker-compose.yml logs` |
| Access website | `https://abdothma.42.fr` |
| Access admin panel | `https://abdothma.42.fr/wp-admin` |
| Stop & clean | `make clean` |
| Full reset | `make fclean` |
| Monitor resources | `docker stats` |

---

For additional help or technical details, refer to the Developer Documentation (`DEV_DOC.md`).
