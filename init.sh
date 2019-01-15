# ==============================================================================
# Initialize database
# This will run the scripts inside db/init.d/ and restore the data and user.
docker-compose run --rm db

# ==============================================================================
# Create fake certs
# The nginx server won't run without these files,
# so we have to make a few in the meantime.
docker-compose run --rm --entrypoint sh \
    certbot /make-certs.sh datachile.io es.datachile.io en.datachile.io static.datachile.io chilecube.datawheel.us

# ==============================================================================
docker-compose up -d

docker-compose run --rm --entrypoint sh \
    certbot /first-run.sh datachile.io es.datachile.io en.datachile.io static.datachile.io chilecube.datawheel.us
