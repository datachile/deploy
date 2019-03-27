# ==============================================================================
# MAKE PERMANENT STORAGE FOLDERS
sudo mkdir /datastore
sudo mkdir /datastore/dumps
sudo mkdir /datastore/postgres
sudo mkdir /datastore/cache-mondrian
sudo mkdir /datastore/cache-canon

# ==============================================================================
# INITIALIZE DATABASE
# This will run the scripts inside db/init.d/ and restore the data and user.
docker-compose run --rm db

# ==============================================================================
# CREATE FAKE CERTIFICATES
# The nginx server won't run without the certificates, so we have to make a few
# in the meantime. Input the root domain only.
docker-compose run --rm --entrypoint sh \
    certbot /fake-certs.sh datachile.io

# ==============================================================================
# CREATE CONTAINERS
# Let's make the containers this time.
docker-compose up -d

# ==============================================================================
# GENERATE THE ACTUAL CERTIFICATES
# Time to run certbot.
# Input all the domains that will be handled; the first one must be 
# the root domain.
docker-compose run --rm --entrypoint sh \
    certbot /real-certs.sh datachile.io \
        www.datachile.io \
        es.datachile.io \
        en.datachile.io \
        chilecube.datachile.io \
        static.datachile.io
