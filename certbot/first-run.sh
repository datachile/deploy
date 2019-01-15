#!/bin/sh

rm -rf "/etc/letsencrypt/$1"

comm="certbot certonly --webroot "
comm+="--dry-run "
comm+="--agree-tos "
comm+="-m $EMAIL "
comm+="--cert-name $1 "
comm+="-w /tmp/certbotacme "

for domain in "$@"
do
    comm+="-d $domain "
done

eval $comm