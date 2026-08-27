#!/bin/sh
set -e

DATADIR=/var/lib/mysql
SOCK=/run/mysqld/mysqld.sock

ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

if [ -z "$(ls -A $DATADIR 2>/dev/null)" ]; then
    echo "[init_db] First run: initializing MariaDB data directory..."
	chown -R mysql:mysql "$DATADIR"
    mariadb-install-db --user=mysql --datadir="$DATADIR" >/dev/null

    mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCK" &
    tmp_pid="$!"


    for i in $(seq 1 30); do
        mysqladmin --socket="$SOCK" ping >/dev/null 2>&1 && break
		echo connecting failed so trying again
        sleep 1
    done

    mysql --socket="$SOCK" -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
EOSQL

    mysqladmin --socket="$SOCK" -u root -p"${ROOT_PASSWORD}" shutdown
    wait "$tmp_pid" 2>/dev/null || true
    echo "[init_db] Database initialized."
fi

exec mysqld --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0
