#!/bin/bash

export MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-password}"

# Set root password
if [ "${MYSQL_ROOT_PASSWORD:-false}" != "false" && $(ls -A "/var/lib/mysql" | wc -l) -eq 0 ]; then
    cat "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PWD'; FLUSH PRIVILEGES;" > "/opt/init.sql"
    chmod 777 "/opt/init.sql"
    mysqld --initialize --init-file=/opt/init.sql --defaults-file=/etc/my.cnf --datadir=/var/lib/mysql --user=mysql --character-set-server=utf8mb4 --collation-server=utf8mb4_general_ci

    # mysqld_safe --skip-grant-tables
    sleep 5
    # mysql -u root -e "USE mysql; UPDATE user SET authentication_string=PASSWORD('new_password') WHERE User='root'; FLUSH PRIVILEGES;"
    mysqladmin -u root -p shutdown
fi

# Function: _check_my_rocks_db_status
# Description: Checks status of rocksdb table engine.
# Parameters: None
# Returns: None

_check_my_rocks_db_status() {
    mysql -u "root" -e "SHOW ENGINES" | grep "ROCKSDB" | awk '{print $2}'
}

# Function: _enable_my_rocks_db_status
# Description: Function to enable and check rocksdb table engine..
# Parameters: None
# Returns: None

_enable_my_rocks_db_status(){
    ps-admin --enable-rocksdb -u root
    if [ "$(_check_my_rocks_db_status )" = "YES" ]; then
        echo "RocksDB is now enabled"
    else
        echo "RocksDB is still disabled"
    fi
}

# Function: _queue_enable_rocks_db
# Description: Queue enabling rocksdb table engine.
# Parameters: None
# Returns: None

_queue_enable_rocks_db() {

    while nc -z -w1 localhost 3306; do
        # echo "[ERROR] mysql:3306 is CLOSED."
        sleep 3s
    done

    # echo "[SUCCESS] mysql:3306 is OPEN."

    sleep 6s

    if [ "$(_check_my_rocks_db_status)" = "YES" ]; then
        echo "RocksDB is enabled"
    else
      echo "RocksDB is not enabled"
      _enable_my_rocks_db_status
    fi
}

# Background queue function, to enable rocksdb
_queue_enable_rocks_db &

mysqld