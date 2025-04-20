#!/bin/sh

# Run the perl script every few minutes

while true; do
  /root/vimexx-dns -ddns $VIMEXX_DNS_DOMAIN
  sleep 300
done
