#!/bin/bash

# exit script if any command exits with a non-zero status
set -e

# create the `datachile` user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER datachile WITH PASSWORD 'please remember to put a password here';
EOSQL

# insert the backup `datachile_dump.custom` file
# see example to get the command to get this file from another production server
pg_restore -v --username "$POSTGRES_USER" -C -d postgres /docker-entrypoint-initdb.d/datachile_dump.custom

# grant privileges on the `datachile` database to the `datachile` user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE datachile TO datachile;
EOSQL
