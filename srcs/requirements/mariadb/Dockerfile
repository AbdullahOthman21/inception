FROM debian:bookworm-slim

RUN apt update && apt install -y mariadb-server

RUN rm -rf /var/lib/mysql/*

EXPOSE 3306

COPY script.sh /script.sh

ENTRYPOINT ["bash", "/script.sh"]
