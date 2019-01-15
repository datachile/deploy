# datachile deployment procedure

## Configuration files

Before creating the containers to run datachile, there are some files required
that must be created/edited/copied from another instance. This file contains the
procedure to obtain these files, and to run the compose file for the first time.

### docker volumes

This compose file will generate 3 volumes

### certbot

The certbot instance created by this compose file stops immediately after running.
It can't get/renew certificates by itself; it just contains the certbot executable
that can be ran from outside.
Before 

### db

The current db is a postgres instance, based on the `postgres:latest` docker image.
Add database initialization files to `db/init`. The files can be `.sql`, `.sql.gz`,
and `.sh`, and are run by name in alphabetical order. If you need to modify the 
initialization commands, edit the files in this folder, and make sure they are
named in order.

To initialize datachile database you need to ingest the data for mondrian.
You can use the ETL procedure, but if there's another instance running in another
server, you can dump that database and ingest it using the included files.
The `datachile_dump.custom.example` contains the command to get the file from
the postgres database in the other instance.
The `01-init.sh` will initialize that file. You will need to set a password in
line 8, as it will be required in the `mondrian:config.yaml` file.

### mondrian

The mondrian container runs an instance of Pentaho Mondrian + `jazzido/mondrian-rest`.
It is built from the `datachile/datachile-mondrian` repository.
This folder needs 2 files: 

- A `config.yaml`, with the required info to connect to the database
- A `schema.xml`, with the mondrian cube schema to be used

### canon

The canon container builds the frontend.
It is built from the `datachile/datachile` repository.
This container doesn't require special files, but ensure the environment variables
are correctly set.