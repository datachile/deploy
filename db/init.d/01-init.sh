#!/bin/bash

# exit script if any command exits with a non-zero status
set -e

# create the `datachile` user, create the `datachile` database, and
# grant privileges on the `datachile` database to the `datachile` user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER datachile WITH PASSWORD 'please remember to put a password here';
    DROP DATABASE IF EXISTS datachile;
    CREATE DATABASE datachile WITH OWNER = datachile TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';
EOSQL

# the dumped file should have been previously put on /datastore/dumps
# docker will mount this folder on /app/dumps
NEWEST_DUMP=`ls -t /app/dumps | head -n1`
if [ ${NEWEST_DUMP: -4} == ".sql" ]; then
    echo "Inserting $NEWEST_DUMP file..."
    psql -v --username datachile --dbname datachile < "/app/dumps/$NEWEST_DUMP"
elif [ ${NEWEST_DUMP: -5} == ".sqlc" ]; then
    echo "Restoring $NEWEST_DUMP file..."
    pg_restore -v --username datachile --dbname datachile --no-owner "/app/dumps/$NEWEST_DUMP"
else
   echo "No dump file present."
fi

