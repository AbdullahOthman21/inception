*This activity has been created as part of the 42 curriculum by abdothma.*

# Inception

## Description

This project is a Docker-based infrastructure exercise designed to simulate a small but complete web application stack. The main goal is to deploy a WordPress website served through Nginx and backed by a MariaDB database, all while respecting the constraints of containerization, network isolation, and service orchestration.

The activity focuses on understanding how multiple services can be organized and run independently inside containers, while still communicating securely and efficiently with each other. It also introduces the concepts of environment configuration, persistent data, and runtime orchestration with Docker Compose.

The result is a simple but realistic deployment where the frontend is served over HTTPS, the application logic runs inside a PHP-FPM container, and the database remains isolated in its own container.

## Instructions

### Requirements

- Docker
- Docker Compose
- A Linux environment with access to `sudo` if needed for volume cleanup

### Setup

1. Clone the repository:

```bash
git clone https://github.com/AbdullahOthman21/inception.git
cd inception
```

2. Create the environment file from the example:

```bash
cp srcs/env_example srcs/.env
```

3. Update the values inside `srcs/.env` if needed for your environment.

4. Make sure the bind-mounted data directories exist or they will be created automatically when the project starts:

```bash
mkdir -p /home/me/data/wordpress /home/me/data/mariadb
```

### Run the project

```bash
make run
```

This command builds the required Docker images, creates the Docker network, starts the services, and mounts the persistent data directories.

### Access the application

The application is configured to run behind HTTPS on the domain `abdothma.42.fr`.

If necessary, add the hostname to your local hosts file:

```bash
sudo sh -c 'echo "127.0.0.1 abdothma.42.fr" >> /etc/hosts'
```

Then open the following URL in a browser:

```text
https://abdothma.42.fr
```

### Useful commands

Stop the containers:

```bash
make stop
```

Stop and remove containers, but keep the project structure:

```bash
make clean
```

Remove everything including volumes and generated Docker images:

```bash
make fclean
```

## Project Description

### Use of Docker

This project is built around Docker containers to isolate each service and to make the application portable and reproducible. The deployment includes three main containers:

- `nginx`: exposes HTTPS and forwards PHP requests to the WordPress service
- `wordpress`: runs WordPress with PHP-FPM and configures the application runtime
- `mariadb`: provides the database backend and initializes the required schema and users

Each service has its own Docker image defined in `srcs/requirements/*/Dockerfile`, and the orchestration is handled by `srcs/docker-compose.yml`.

The project uses a custom Docker network named `inception`, which allows internal communication between containers without exposing the database directly to the host. The containers also rely on bind-mounted volumes to persist the WordPress files and MariaDB data on the host filesystem.

### Included sources

The source files included in this project are organized under `srcs/`:

- `srcs/docker-compose.yml` — container orchestration and service configuration
- `srcs/env_example` — example environment variables used by the services
- `srcs/requirements/nginx/` — Nginx Dockerfile and TLS configuration
- `srcs/requirements/wordpress/` — WordPress Dockerfile and entrypoint installation script
- `srcs/requirements/mariadb/` — MariaDB Dockerfile and initialization script
- `Makefile` — convenient tasks for build, start, stop, and cleanup

### Main design choices

The choices in this project are meant to reflect key DevOps and system-administration principles:

- Service separation: each component is isolated in its own container
- Minimal dependencies: each container installs only what it needs
- Persistent storage: data is stored outside the container filesystem
- Secure communication: TLS is configured in Nginx and services communicate through private Docker networking
- Reproducibility: infrastructure is declared in code and versioned in the repository

### Virtual Machines vs Docker

A virtual machine includes a full guest operating system, kernel, and system resources. Docker containers are lighter because they share the host kernel and run processes in isolated namespaces and cgroups.

- Virtual machines are more complete and often better for running diverse guest OS environments.
- Docker is much faster to start, uses fewer resources, and is ideal for microservices or lightweight application stacks.
- In this project, Docker is preferred because the application is composed of small, specialized services that do not need full virtualization.

### Secrets vs Environment Variables

Environment variables are useful for non-sensitive configuration values and are simple to pass to containers. They are easy to manage in local development and in small projects.

However, they are not a secure or production-grade secret storage mechanism. Secrets should ideally be managed through dedicated secret stores, encryption, or orchestration-managed secret injection. In this project, variables such as database credentials and WordPress admin credentials are placed in `.env` for classroom simplicity and demonstration, but in production they would be better handled with secure secret management.

This makes the activity a useful demonstration of the tradeoff: convenience vs security.

### Docker Network vs Host Network

Docker networks provide an isolated internal communication layer between containers. This improves encapsulation and reduces the exposure of service ports to the host system. Containers can talk to each other using service names such as `mariadb` and `wordpress` rather than requiring direct host-level routing.

Host networking, by contrast, attaches a container directly to the host network stack. This reduces isolation and can increase exposure and complexity, especially when multiple containers compete for ports or network resources.

For this exercise, a custom bridge network is the better choice because it keeps the services logically separated while still allowing controlled inter-container communication.

### Docker Volumes vs Bind Mounts

A Docker volume is a managed storage abstraction maintained by Docker. It is easier to use for container-managed data and is often more portable across different host environments.

A bind mount maps a host directory directly into a container filesystem. This makes the host path explicit and is useful when the application or developer wants direct access to the data from the host machine.

In this project, bind mounts are used to store WordPress files and MariaDB data under `/home/me/data/wordpress` and `/home/me/data/mariadb`. This choice makes the files accessible on the host and allows easier debugging, inspection, and persistence outside the container lifecycle.

## Resources

### Reference material

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- Nginx documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- WordPress documentation: https://wordpress.org/documentation/
- WP-CLI documentation: https://make.wordpress.org/cli/
- Official Alpine Linux docs: https://wiki.alpinelinux.org/wiki/Main_Page

### Tutorials and conceptual references

- Docker official tutorials: https://docs.docker.com/get-started/
- Compose networking overview: https://docs.docker.com/compose/networking/
- Docker volumes and bind mounts: https://docs.docker.com/storage/
- Nginx TLS and HTTPS basics: https://nginx.org/en/docs/http/configuring_https_servers.html
- Container security overview: https://docs.docker.com/develop/security-best-practices/

### How AI was used

AI was used as a support tool throughout the activity for:

- understanding the Docker architecture and service dependencies
- explaining the role of Nginx, WordPress, and MariaDB in the stack
- validating the project structure and README organization
- clarifying the differences between Docker networking, environment variables, and persistent storage
- helping draft a clear and accurate technical description of the design choices and execution steps

In particular, AI was helpful for the conceptual explanation of:

- Docker vs virtual machines
- secrets vs environment variables
- Docker network vs host network
- volumes vs bind mounts
- project description and documentation structure

It was not used to replace the actual implementation of the project, but rather to support understanding, explanation, and documentation of the work.

## Conclusion

This project demonstrates how a small web platform can be built using Docker containers, with each service isolated and coordinated through a simple yet powerful orchestration setup. It introduces the core concepts needed for modern containerized deployments: service composition, persistent storage, network isolation, and configuration management.

It also serves as a solid introduction to infrastructure as code, where the full environment is defined in files and can be reproduced consistently across different machines.

---

If you want, I can also generate a more polished 42-style README with a stronger academic tone or a more concise version for GitHub.
