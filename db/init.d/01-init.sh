#!/bin/bash

# exit script if any command exits with a non-zero status
set -e

# we use `--dbname "$POSTGRES_DB"` to prevent blockings

# create the `datachile` user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER datachile WITH PASSWORD 'please remember to put a password here';
EOSQL

# insert the backup `dump.custom` file
# we cannot use a *.sql file here directly, or postgres will use it
# see example to get the command to get this file from another production server
if [ -f /docker-entrypoint-initdb.d/dump.sql.custom ]; then
    echo "Using a dump.sql.custom file"
    psql -v --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < /docker-entrypoint-initdb.d/dump.sql.custom
elif [ -f /docker-entrypoint-initdb.d/dump.custom ]; then
    pg_restore -v -C --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" /docker-entrypoint-initdb.d/dump.custom
else
   echo "No dump file present."
fi

# grant privileges on the `datachile` database to the `datachile` user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE datachile TO datachile;
EOSQL
