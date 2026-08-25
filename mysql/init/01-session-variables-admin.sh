#!/bin/bash
set -e

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
GRANT SESSION_VARIABLES_ADMIN ON *.* TO '${MYSQL_USER}'@'%';
GRANT SESSION_VARIABLES_ADMIN ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;
EOSQL
