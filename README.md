# vimexx-dns

Use the API to manipulate DNS records for domains hosted on Vimexx.eu.

# Description

This script uses the Vimexx API to add or delete DNS records for a domain
hosted by the Vimexx nameservers.

The main purpose of this script is to automate the creation and renewal of
[Let's Encrypt](https://letsencrypt.org/) SSL certificates, using [Certbot](https://certbot.eff.org/) to validate domain
ownership using a [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/), and to automate this procedure.

It is also possible to update an A record in a domain with the current
dynamic IP address of your internet connection, thus avoiding the use of
a dynamic DNS service, and instead, use your own domain to keep track of
any dynamic IP addresses you have.

# Installation

Simply copy the script vimexx-dns to any location, then install the necessary dependencies.

## Dependencies

```
sudo apt install libappconfig-std-perl libjson-perl
```

# Setup

## Vimexx API credentials

This script will require access to the API provided by Vimexx.

- Login to your accout at [Vimexx](https://my.vimexx.eu/)
- Create a [WHMCS API secret](https://my.vimexx.eu/api)
- Take note of the Client ID and the Client Secret

## Create a configuration file

The script will search for a configuration file in the following locations:

- /etc/vimexx-dns
- $HOME/.vimexx-dns
- .vimexx-dns in the working directory

The configuration should contain this:

```
[login]
id = <Client ID>
secret = <Client Secret>
username = <Your Vimexx username>
password = <Your Vimexx password>
```

(!) Be carefull where and how you keep this file, as it will allow full access to your DNS records.

# Integration with Certbot

## Install Certbot

The first step in installing Certbot on a secure host, preferably not a public-facing (web) server.
Follow the instructions provided [here](https://certbot.eff.org/instructions).

## Requesting a new certificate

Run the following command to request a new certificate for a domain `your.domain.com`

```
certbot certonly --manual --manual-auth-hook authenticator.sh --manual-cleanup-hook cleanup.sh --preferred-challenges dns -d your.domain.com
```

This does the following:

- A DNS-01 challenge is generated
- certbot executes the script 'authenticator.sh' which must create the requested DNS record for your domain
- The DNS record that was created will be checked, and if succesfull, a new Let's Encrypt certificate will be made available
- Certbot will then execute the script `cleanup.sh', which should remove the DNS record that was previously created

### authenticator.sh

```
# cat authenticator.sh
#!/bin/sh
/path/to/vimexx-dns $CERTBOT_DOMAIN $CERTBOT_VALIDATION
# Give DNS some time to properly propagate
sleep 15
```

### cleanup.sh

```
# cat cleanup.sh
#!/bin/sh
/path/to/vimexx-dns -d $CERTBOT_DOMAIN
```

This script is also the ideal place to copy the freshly generated certificates to the actual (web) server that requires the certificates.
This can be easily automated with a combination of SSH and public/private key authentication.

## Renewing a certificate

Let's Encrypt certificates are valid for 3 months. It will only be possible to renew a certificate when the expiration date is less that a month or so. It is recommended to try and renew all your certificates every day. Any certificates that are not yet up for renewal will simply be skipped.

```
# Renew a single certificate
certbot --cert-name your.domain.com --preferred-challenges dns renew
```

```
# Renew all certificates
certbot --preferred-challenges dns renew
```

# Running as a dynamic DNS client

```
vimexx-dns -ddns myhomeserver.example.com
```
This will create or update the DNS A record for 'myhomeserver.example.com' with your current public IPv4 address.