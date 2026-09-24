#!/bin/bash
set -e

cd /var/www/html

# --- Download WordPress core if this volume is empty ---
if [ ! -f wp-load.php ]; then
  echo "wordpress: downloading core..."
  wp core download --allow-root
fi

# --- Generate wp-config.php if missing ---
if [ ! -f wp-config.php ]; then
  echo "wordpress: writing wp-config.php..."
  wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
	--dbpass="$DB_USER_PASSWORD" \
    --dbhost="mariadb" \
    --skip-check \
    --allow-root
fi

# --- Install WordPress + create users, only once ---
if ! wp core is-installed --allow-root; then
  echo "wordpress: running core install..."
  wp core install \
    --url="$URL" \
	--title="inception" \
    --admin_user="$WORDPRESS_ADMIN" \
	--admin_password="$WORDPRESS_PASSWORD" \
    --admin_email="${WORDPRESS_ADMIN}@gmail.com" \
    --skip-email \
    --allow-root

  echo "wordpress: creating second (non-admin) user..."
  wp user create "$WORDPRESS_USER" "${WORDPRESS_USER}@gmail.com" \
    --role=author \
	--user_pass="$WORDPRESS_PASSWORD" \
    --allow-root
fi

chown -R nobody:nobody /var/www/html

echo "wordpress: starting php-fpm83 in the foreground"
exec php-fpm83 -F
