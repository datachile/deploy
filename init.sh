# ##############################################################################
# INITIALIZATION SCRIPT
# ##############################################################################
# This scripts contains the approximate steps to follow to deploy a new server.
# Before executing this script, make sure all the previous steps mentioned in
# the README.md file were followed and checked.
# You can also execute every step in this file on your own, just make sure the 
# parameters you use are correctly set. If you need help with a script, check
# the instructions in that script file.

# ==============================================================================
# VARIABLE ASSIGNATION
DOMAIN=$1
SUBDOMAINS=(www es en chilecube static)

for ix in ${!SUBDOMAINS[*]}
do
    SUBDOMAINS[$ix]="${SUBDOMAINS[$ix]}.$DOMAIN"
done

# ==============================================================================
# MAKE PERMANENT STORAGE FOLDERS
sudo mkdir -p /datastore/cache-canon
sudo mkdir -p /datastore/cache-mondrian
sudo mkdir -p /datastore/dumps
sudo mkdir -p /datastore/postgres
sudo mkdir -p /datastore/public
sudo mkdir -p /datastore/shared

# ==============================================================================
# INITIALIZE DATABASE
# This will run the scripts inside ./db/init.d/, and restore the data and user.
docker-compose run --rm db

# ==============================================================================
# CREATE FAKE CERTIFICATES
# The nginx server won't run without the certificates, so we have to make a few
# in the meantime.
docker-compose run --rm --entrypoint sh certbot /fake-certs.sh $DOMAIN

# ==============================================================================
# CREATE CONTAINERS
# Let's make the containers this time.
docker-compose up -d

# ==============================================================================
# GENERATE THE ACTUAL CERTIFICATES
# Time to run certbot.
docker-compose run --rm --entrypoint sh certbot /real-certs.sh $DOMAIN ${SUBDOMAINS[*]}

# ==============================================================================
# RESTART EVERYTHING
# Hoping we got the certificate correctly, restart all the containers.
# We could just restart the nginx container, but let's play safe.
docker-compose restart
