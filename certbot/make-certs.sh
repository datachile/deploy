for domain in "$@"
do
    echo "Generating fake certs for $domain..."
    echo "----------"
    mkdir -p "/etc/letsencrypt/live/$domain"
    openssl req -x509 -nodes -newkey rsa:1024 -days 1\
        -keyout "/etc/letsencrypt/live/$domain/privkey.pem" \
        -out "/etc/letsencrypt/live/$domain/fullchain.pem" \
        -subj '/CN=localhost'
done

echo "Generating a Diffie-Hellman prime to use"
echo "----------"
openssl dhparam -dsaparam -out /etc/letsencrypt/dhparam.pem 4096
