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
# MAKE PERMANENT STORAGE FOLDERS
# If you followed the instructions on README.md, these should be created by now
# but just in case we will create them again if they not exist.
sudo mkdir -p /datastore/cache-canon
sudo mkdir -p /datastore/cache-mondrian
sudo mkdir -p /datastore/dumps
sudo mkdir -p /datastore/postgres
sudo mkdir -p /datastore/public
sudo mkdir -p /datastore/shared

# ==============================================================================
# CHECK IF REQUIRED FILES EXIST
REQUIRED_FILES=(./mondrian/config.yaml ./mondrian/schema.xml)
for file in ${REQUIRED_FILES[*]}; do
    if [ ! -f $file ]; then
        echo "File doesn't exists: $file"
        exit 1
    fi
done

# ==============================================================================
# VARIABLE ASSIGNATION
DOMAIN=$1

# This array sets which subdomains will get a Let's Encrypt certificate.
SUBDOMAINS=(www es en chilecube static)

for ix in ${!SUBDOMAINS[*]}; do
    SUBDOMAINS[$ix]="${SUBDOMAINS[$ix]}.$DOMAIN"
done

# ==============================================================================
# APPLY DOMAIN TO CONFIGURATION
# replace dummy domain in hosts and docker compose file
sed -i "s/datachile.localhost/$DOMAIN/g" ./docker-compose.yml
sed -i "s/datachile.localhost/$DOMAIN/g" ./nginx/hosts/*.conf
# create a file with references to the letsencrypt domain
echo "ssl_certificate      /etc/letsencrypt/live/$DOMAIN/fullchain.pem;" > "./nginx/ssl/$DOMAIN"
echo "ssl_certificate_key  /etc/letsencrypt/live/$DOMAIN/privkey.pem;" >> "./nginx/ssl/$DOMAIN"

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
# SWAP MONDRIAN CONFIGURATION TO SUPERUSER MOMENTARILY
# Mondrian needs to create some extensions and functions in the database, and
# needs superuser permissions for that. We will restore the normal user later.
mv ./mondrian/config.yaml ./mondrian/config.user.yaml
mv ./mondrian/config.su.yaml ./mondrian/config.yaml

# ==============================================================================
# CREATE CONTAINERS
# Let's make the containers this time.
docker-compose up -d

# ==============================================================================
# GENERATE THE ACTUAL CERTIFICATES
# Time to run certbot.
docker-compose run --rm --entrypoint sh certbot /real-certs.sh $DOMAIN ${SUBDOMAINS[*]}

# ==============================================================================
# RESTORE MONDRIAN CONFIGURATION TO NORMAL USER
# I promised it.
mv ./mondrian/config.yaml ./mondrian/config.su.yaml
mv ./mondrian/config.user.yaml ./mondrian/config.yaml

# ==============================================================================
# RESTART EVERYTHING
# Hoping we got the certificate correctly, restart all the containers.
# We could just restart the nginx container, but let's play safe.
docker-compose restart
