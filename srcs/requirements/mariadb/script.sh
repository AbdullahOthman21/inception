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
CREATE DATABASE \`${DB_NAME}\`;
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
CREATE USER '${DB_ADMIN}'@'%' IDENTIFIED BY '${DB_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_ADMIN}'@'%';
FLUSH PRIVILEGES;
EOF
	mysqladmin -u root shutdown
	wait $!
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0
