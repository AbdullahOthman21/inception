FROM alpine:3.23

RUN apk add mariadb mariadb-client

EXPOSE 3306

COPY script.sh /script.sh

ENTRYPOINT ["sh", "/script.sh"]
