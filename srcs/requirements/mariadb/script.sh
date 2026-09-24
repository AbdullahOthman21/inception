mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

	mariadbd &
	sleep 5

	mariadb <<EOF
		CREATE DATABASE \`${DB_NAME}\`;
		CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
		CREATE USER '${DB_ADMIN}'@'%' IDENTIFIED BY '${DB_ADMIN_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_ADMIN}'@'%';
		FLUSH PRIVILEGES;
		SHUTDOWN;
EOF
	wait $!
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0
