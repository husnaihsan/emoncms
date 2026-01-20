#!/usr/bin/env bash
set -euo pipefail

echo "[init] Preparing runtime directories..."

# MariaDB runtime dirs
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

# Ensure feed data dirs exist (matches settings.ini)
mkdir -p /var/opt/emoncms/phpfina /var/opt/emoncms/phptimeseries
chown -R www-data:www-data /var/opt/emoncms

# Initialize MariaDB on first run
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "[init] Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

echo "[init] Starting MariaDB (temporary, for DB/user setup)..."
/usr/sbin/mysqld --datadir=/var/lib/mysql --user=mysql --skip-networking --socket=/var/run/mysqld/mysqld.sock &
MYSQL_PID=$!

# Wait until MariaDB is ready
echo "[init] Waiting for MariaDB socket..."
for i in {1..60}; do
  if mariadb --protocol=socket -uroot -S /var/run/mysqld/mysqld.sock -e "SELECT 1;" >/dev/null 2>&1; then
    echo "[init] MariaDB is ready."
    break
  fi
  sleep 1
done

# Create DB and user
echo "[init] Creating database 'emoncms' and user 'emoncms'..."
mariadb --protocol=socket -uroot -S /var/run/mysqld/mysqld.sock <<'SQL'
CREATE DATABASE IF NOT EXISTS emoncms;
CREATE USER IF NOT EXISTS 'emoncms'@'localhost' IDENTIFIED BY 'emoncms';
GRANT ALL PRIVILEGES ON emoncms.* TO 'emoncms'@'localhost';
FLUSH PRIVILEGES;
SQL

# Stop temporary MariaDB
echo "[init] Stopping temporary MariaDB..."
kill "$MYSQL_PID" || true
sleep 2

# Ensure settings.ini exists (should be copied during build)
if [ ! -f /var/www/html/settings.ini ]; then
  echo "[init] settings.ini not found, attempting to copy template..."
  if [ -f /var/www/html/example.settings.ini ]; then
    cp /var/www/html/example.settings.ini /var/www/html/settings.ini
  fi
fi

echo "[init] Launching supervisord (Apache + Redis + MariaDB + Mosquitto + workers)..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
