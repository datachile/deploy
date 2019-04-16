# datachile deployment procedure

The datachile project has been configured to run on docker containers. Make sure both `docker` and `docker-compose` is installed and running in the machine you intend to setup datachile. You also must previously prepared the DNS configuration for the domain this machine will be located. This is a required step, as the virtual hosts are configured to run for a domain.
The deployment procedure can be divided in 2 steps: preparation, and setup, however, it's convenient you understand the internal structure in each container before you start the deployment.
Each container runs a different part of the project, and has some common elements that connects them.

### restui
The *restui* container builds an instance of [mondrian-rest-ui](https://github.com/Datawheel/mondrian-rest-ui/), which is useful to explore and debug the cubes available. This container will run the build procedure during the setup, and then will exit with code (1). The resulting build will be saved in a docker volume, which is shared with the nginx container.

### certbot
The *certbot* container contains an instance of EFF's Certbot, to get the SSL certificates for the domain. This container runs on setup but doesn't do anything; it exits with code (1) immediately. Instead, this container is meant to be run from the outside with `docker-compose run certbot` commands.
The obtained certificates are saved in a docker volume, and shared with the nginx container.

### db
The *db* container runs a postgres instance, based on the official `postgres:latest` docker image, which will contain the main database.
According to the instructions for the official [postgres image](https://hub.docker.com/_/postgres/), the first time the container is ran, it checks for the database files in the internal `/var/lib/postgresql` folder (which is mounted as a external volume from `/datastore/postgres`). If the files needed don't exist, it will create them, and then run all the scripts in the internal `/docker-entrypoint-initdb.d` folder (which is mounted from the external `./db/init.d` folder), else it will just run the postgres instance as normally.
Additionally, the folders `/datastore/dumps` and `/datastore/shared` are mounted in the internal `/app/dumps` and `/app/shared` folders of the container, so you can export and import dumps and other files from other containers and with the host machine.

### mondrian
The *mondrian* container runs an instance of `mondrian-rest`, built from the [datachile-mondrian](https://github.com/datachile/datachile-mondrian) repository. The container will mount the external `./mondrian/schema.xml` and `./mondrian/config.yaml` files, so make sure both exists. They're not included in the repo by default, but you can rename `config.yaml.example` if you haven't done modifications to the `db` container. The `schema.xml` can be obtained from the [datachile-mondrian](https://github.com/datachile/datachile-mondrian) repository, and you can update it and restart the container to apply the changes.
This container also mounts `/datastore/shared` into the internal `/app/shared` folder.

### canon
The *canon* container runs the frontend of the datachile project. Canon is the name of the framework datachile is built upon. On the first run, `docker-compose` will build an image called `datachile_canon`, which contains the needed packages to run canon. To run the container, make sure all the needed environment variables are set in the `docker-compose.yml` file.
The container mounts a docker volume to save the static files, so they can be served directly by nginx, and the `/datastore/shared` folder into the internal `/app/shared` path.

### nginx
The *nginx* container connects all the other containers and expose the needed content to the internet. Only ports 80 and 443 are exposed, and by default all http traffic to port 80 is redirected to the https protocol. The *nginx* container will run when the canon, restui, and mondrian containers start correctly.
The configuration files are located in `./nginx/`, and are classified on 3 folders:

- `hosts/`, which is mounted in `/etc/nginx/conf.d/`, contains the configuration for the virtual hosts nginx will handle.
- `snippets/`, mounted in `/etc/nginx/snippets/`, contains shared directives between various hosts files.
- `ssl/`, mounted in `/etc/nginx/ssl/`, contains the snippets that handle the path to the ssl certificates each virtual host needs.

Besides the volumes previously mentioned, there's a docker volume to handle the acme challenge files, the external `/datastore/cache-canon` and `/datastore/cache-mondrian` folders are mounted to the internal `/ncache/canon` and `/ncache/mondrian` to save the cache for canon and mondrian requests, and the external `/datastore/shared` folder is mounted to the internal `/app/shared` to access files from other containers.

## Preparation step

Before meddling with docker containers, you must make sure the configuration files are correctly set. There are some example files that you can just rename to the needed file, and there are some other files that will need to be edited and/or downloaded from other repository.

### The `/datastore` folder
Create a `datastore` folder at the root level of the filesystem. This folder will contain all the big files needed to run the containers, and some other files with high I/O. It's recommended a SSD is mounted in this folder.
When the folder is prepared, create the `cache-canon`, `cache-mondrian`, `dumps`, `postgres`, `public`, and `shared` folders inside.

### db
To initialize the database you will need to ingest the data for mondrian.
You can use the ETL procedure, but if there's another database instance running in another server, you can dump that database and ingest it in this machine using the files included in this repository.
The command to export the database to a file from another postgres database is:

```bash
pg_dump --no-acl --no-owner --file=/absolute/path/to/file.sql <dbname>
```

This will generate a file.sql in the intended path. The filename doesn't matter, but it should have `.sql` extension. Move this file to `/datastore/dumps`, and the script will ingest it automatically. Inside the db container, the file will be available on `/app/dumps`. 
The `01-init.sh` will create the database, the user, and will insert that file. You can change the connection data for that user here, but remember to also update it in the `./mondrian/config.yaml` file. For more information on what the `01-init.sh` file does, [check its readme file](db/init.d/README.md).

### mondrian
This folder needs 2 files: 

- A `config.yaml`, with the required info to connect to the database. You can rename the `config.yaml.example` file an use it if you haven't changed anything in `./db/init.d/01-init.sh`.
- A `schema.xml`, with the mondrian cube schema to be used. You can use the one available in the [datachile-mondrian](https://github.com/datachile/datachile-mondrian) repository.

On the first run, Mondrian will require to create a few functions and extensions in the database. To do this, the connection used must be for a superuser. The `init.sh` script will take care of the replacement, so take it into account if you change the access credentials for the default postgres superuser. The file `./mondrian/config.su.yaml` has the connection parameters for this.

### canon
Make sure the environment variables are correctly set. No other files are needed here.

### nginx
Check the hosts are correctly set. All relative paths use the internal `/etc/nginx/` folder as base,  absolute paths start with a `/`. Especially important is to check that the `server_name` directives match the root domain where this instance will run, the `./nginx/ssl/<root_domain>` exist, and the virtual hosts refer to this file as intended.
The included virtual host files suppose `chilecube` (the endpoint where the mondrian-rest api is available) will run as a subdomain of the root domain. If that's not the case, make the needed modifications, and don't execute the normal setup from the next section.

## Setup step

This repository contains a `./init.sh` with the steps to run the setup. This setup includes making the subfolders in the `/datastore` folder, initializing the database, building the docker images needed, running the containers and getting the SSL certificates.
If everything is configured correctly, run the following command:

```bash
$ bash ./init.sh datachile.io
```

The first argument, `datachile.io` is the root domain where this instance is running. This will do the procedure needed to get the certificates from the Let's Encrypt Authority.

As mentioned in the previous section, if the `chilecube` endpoint won't be hosted as a subdomain of the same root domain, you can't run this file directly. Check the `./init.sh` file to understand the procedure it does.
