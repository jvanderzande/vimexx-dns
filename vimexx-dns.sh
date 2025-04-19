#!/bin/sh

# Create the configuration file with the secrets.
# This way there's no need to change the perl script!

cat <<EOF > /etc/vimexx-dns
[login]
id = $VIMEXX_DNS_ID
secret = $VIMEXX_DNS_SECRET
username = $VIMEXX_DNS_USERNAME
password = $VIMEXX_DNS_PASSWORD
EOF

# Run the perl script every few minutes

while true; do
  /bin/vimexx-dns -ddns $VIMEXX_DNS_DOMAIN
  sleep 300
done
