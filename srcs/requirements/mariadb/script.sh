mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

# Read secrets from mounted files
DB_ADMIN_PASSWORD=$(cat /run/secrets/db_admin_password)
DB_USER_PASSWORD=$(cat /run/secrets/db_user_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

	mariadbd &
	sleep 5

	mariadb <<EOF
		CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
		CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
		CREATE USER IF NOT EXISTS '${DB_ADMIN}'@'%' IDENTIFIED BY '${DB_ADMIN_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_ADMIN}'@'%';
		FLUSH PRIVILEGES;
		SHUTDOWN;
EOF
	wait $!
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0
