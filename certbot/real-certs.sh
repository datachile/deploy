#!/bin/sh

rm -rf "/etc/letsencrypt/live/$1"

comm="certbot certonly --webroot"
comm="$comm --agree-tos -m $EMAIL"
comm="$comm --cert-name $1"
comm="$comm -w /tmp/certbot-acme"

for domain in "$@"
do
    comm="$comm -d $domain"
done

eval $comm
