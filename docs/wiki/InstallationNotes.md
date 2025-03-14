# Installation Guide

The only supported way to run tt-rss is under Docker. Official images (AMD64 only) are available
on [Docker Hub](https://hub.docker.com/u/cthulhoo) (preferred) and [Gitlab](https://gitlab.tt-rss.org/tt-rss/tt-rss/container_registry) (fallback).

!!! notice

    Podman is not Docker. Please don't report issues when using Podman or podman-compose.

This setup uses PostgreSQL and runs tt-rss using several containers as outlined below. In a production environment I suggest using an external [Patroni cluster](https://patroni.readthedocs.io/en/latest/)
instead of a single `db` container.

----

Repository commits are signed with the following GPG key:

```
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEYpzS6xYJKwYBBAHaRw8BAQdAmTuuLIwuSTyqQH/pBHdwtUbOrvB0y5s8T+K6
pxk+Vqq0IEFuZHJldyBEb2xnb3YgPGZveEBmYWtlY2FrZS5vcmc+iJMEExYKADsW
IQSuZ4ygEAtUcvjwk3MaVrT6JdSvKgUCYpzS6wIbAwULCQgHAgIiAgYVCgkICwIE
FgIDAQIeBwIXgAAKCRAaVrT6JdSvKmysAP0RL3Du5AHEJaowqO4lNMkpaz+74Gzc
l2/G1RrWjlWDxAEA1yudUfy4VcKJWbckq/73Iocz2qOEOpIHb9KHBrNupQa4OARi
nNLrEgorBgEEAZdVAQUBAQdABGxt5TSwGQx40DoQv7tFAuE2zL3gtivoZlpa93sK
rjMDAQgHiHgEGBYKACAWIQSuZ4ygEAtUcvjwk3MaVrT6JdSvKgUCYpzS6wIbDAAK
CRAaVrT6JdSvKta2AP4hBFkHaefkE8sqf6mAWuhYChYRWpRQffD8eapLkVpNLgEA
jSU28KYibF0x/db/jghtJ0b0kOLONIBOSuD7E5jFAgc=
=wZ+H
-----END PGP PUBLIC KEY BLOCK-----
```

Docker images are signed using [cosign](https://docs.sigstore.dev/cosign/verifying/verify/). You can verify the signatures as follows:

Save the following public key as `cosign.pub`:

```
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEtoahWEy+L2JZCyDZ3+sKacGjhLCj
DDZpyS24bZzLoqZ3uEROqDusa9F9gNWP4sd3nbH02Tc0x89x5mM29wVg3w==
-----END PUBLIC KEY-----
```

Verify signature using `cosign`:

```sh
$ cosign verify --key cosign.pub cthulhoo/ttrss-web-nginx:latest \
  --private-infrastructure=true
```

## TL;DR

Place both `.env` and `docker-compose.yml` together in a directory, edit `.env` as you see fit, run `docker compose up -d`.

### .env

```ini
# Put any local modifications here.

# Run FPM under this UID/GID.
# OWNER_UID=1000
# OWNER_GID=1000

# FPM settings.
#PHP_WORKER_MAX_CHILDREN=5
#PHP_WORKER_MEMORY_LIMIT=256M

# ADMIN_USER_* settings are applied on every startup.

# Set admin user password to this value. If not set, random password
# will be generated on startup, look for it in the 'app' container logs.
#ADMIN_USER_PASS=

# Sets admin user access level to this value. Valid values:
# -2 - forbidden to login
# -1 - readonly
#  0 - default user
# 10 - admin
#ADMIN_USER_ACCESS_LEVEL=

# Auto create another user (in addition to built-in admin) unless it already exists.
#AUTO_CREATE_USER=
#AUTO_CREATE_USER_PASS=
#AUTO_CREATE_USER_ACCESS_LEVEL=0

# Default database credentials.
TTRSS_DB_USER=postgres
TTRSS_DB_NAME=postgres
TTRSS_DB_PASS=password

# You can customize other config.php defines by setting overrides here.
# See tt-rss/.docker/app/Dockerfile for a complete list.

# You probably shouldn't disable auth_internal unless you know what you're doing.
# TTRSS_PLUGINS=auth_internal,auth_remote
# TTRSS_SINGLE_USER_MODE=true
# TTRSS_SESSION_COOKIE_LIFETIME=2592000
# TTRSS_FORCE_ARTICLE_PURGE=30
# ...

# Bind exposed port to 127.0.0.1 to run behind reverse proxy on the same host.
# If you plan to expose the container, remove "127.0.0.1:".
HTTP_PORT=127.0.0.1:8280
#HTTP_PORT=8280
```

### docker-compose.yml

```yaml
version: '3'

services:

  # see FAQ entry below if upgrading from a different PostgreSQL major version (e.g. 12 to 15):
  # https://tt-rss.org/wiki/InstallationNotes/#i-got-the-updated-compose-file-above-and-now-my-database-keeps-restarting
  db:
    image: postgres:15-alpine
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - POSTGRES_USER=${TTRSS_DB_USER}
      - POSTGRES_PASSWORD=${TTRSS_DB_PASS}
      - POSTGRES_DB=${TTRSS_DB_NAME}
    volumes:
      - db:/var/lib/postgresql/data

  app:
    image: cthulhoo/ttrss-fpm-pgsql-static:latest
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - app:/var/www/html
      - ./config.d:/opt/tt-rss/config.d:ro
    depends_on:
      - db

#  optional, makes weekly backups of your install
#  backups:
#    image: cthulhoo/ttrss-fpm-pgsql-static:latest
#    restart: unless-stopped
#    env_file:
#      - .env
#    volumes:
#      - backups:/backups
#      - app:/var/www/html
#    depends_on:
#      - db
#    command: /opt/tt-rss/dcron.sh -f

  updater:
    image: cthulhoo/ttrss-fpm-pgsql-static:latest
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - app:/var/www/html
      - ./config.d:/opt/tt-rss/config.d:ro
    depends_on:
      - app
    command: /opt/tt-rss/updater.sh

  web-nginx:
    image: cthulhoo/ttrss-web-nginx:latest
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - ${HTTP_PORT}:80
    volumes:
      - app:/var/www/html:ro
    depends_on:
      - app

volumes:
  db:
  app:
  backups:
```

## FAQ

### Your images won't run on Raspberry Pi!

Sorry, I only make and support AMD64 images, dealing with cross-platform buildx is just too much effort. You'll have to make your own images if you use ARM or 32bit platforms by using an override and running `docker-compose build`.

```yaml
# docker-compose.override.yml
version: '3'

services:
  app:
    image: cthulhoo/ttrss-fpm-pgsql-static:latest
    build:
      dockerfile: .docker/app/Dockerfile
      context: https://git.tt-rss.org/fox/tt-rss.git
      args:
        BUILDKIT_CONTEXT_KEEP_GIT_DIR: 1

  web-nginx:
    image: cthulhoo/ttrss-web-nginx:latest
    build:
      dockerfile: .docker/web-nginx/Dockerfile
      context: https://git.tt-rss.org/fox/tt-rss.git
```

`BUILDKIT_CONTEXT_KEEP_GIT_DIR` build argument is needed to display tt-rss version properly. If that doesn't work for you (no BuildKit?) you'll have to resort to terrible hacks, as described in [this thread](https://community.tt-rss.org/t/tiny-tiny-rss-vunknown-unsupported/6187/7).

!!! warning

    Self-built images are not supported.

### I got the updated compose file above and now my database keeps restarting

Error message: The data directory was initialized by PostgreSQL version 12, which is not compatible with this version 15.4.

Official PostgreSQL containers have no support for migrating data between major versions. You can do one of the following:

1. Replace `postgres:15-alpine` with `postgres:12-alpine` in the compose file (or use `docker-compose.override.yml`, see below) and keep using PG 12;
2. Use [this DB container](https://github.com/pgautoupgrade/docker-pgautoupgrade) which would automatically upgrade the database;
3. Migrate the data manually using pg_dump & restore (somewhat complicated if you haven't done it before);

See also: https://community.tt-rss.org/t/docker-compose-setup-broken-repo-missing/6164/15

### I'm using docker-compose.override.yml and now I'm getting schema update (and other) strange issues

Alternatively, you've changed something related to `/var/www/html/tt-rss` in `docker-compose.yml`.

You screwed up your docker setup somehow, so tt-rss can't update itself to the persistent storage location on startup (this is just an example of one issue, there could be many others).

Related threads:

 - https://community.tt-rss.org/t/schema-version-is-wrong-please-upgrade-the-database/5150
 - https://community.tt-rss.org/t/closed-problem-with-database-schema-update-to-the-latest-version-146-to-145/5138/7?u=fox

Either undo your changes or figure how to fix the problem you created and everything should work properly.

### How do I make it run without /tt-rss/ in the URL, i.e. at website root?

Set the following variables in `.env`:

```ini
APP_WEB_ROOT=/var/www/html/tt-rss
APP_BASE=
```

Don't forget to remove `/tt-rss/` from `TTRSS_SELF_URL_PATH`.

### How do I apply configuration options?

There are two sets of options you can change through the environment - options specific to tt-rss (those are prefixed with `TTRSS_`) and options affecting container behavior.

#### Options specific to tt-rss

For example, to set tt-rss global option `SELF_URL_PATH`, add the following to `.env`:

```ini
TTRSS_SELF_URL_PATH=http://example.com/tt-rss
```

Don't use quotes around values. Note the prefix (`TTRSS_`) before the value.

Look [here](https://tt-rss.org/wiki/GlobalConfig) for more information.

#### Container options

Some options, but not all, are mentioned in `.env-dist`. You can see all available options in the [Dockerfile](https://git.tt-rss.org/fox/tt-rss.git/tree/.docker/app/Dockerfile#n53).

### How do I customize the YML without commiting my changes to git?

You can use [docker-compose.override.yml](https://docs.docker.com/compose/extends/). For example, customize `db` to use a different postgres image:

```yml
# docker-compose.override.yml
version: '3'

services:
  db:
    image: postgres:12-alpine
```

### I'm trying to run CLI tt-rss scripts inside the container and they complain about root

(run in the compose script directory)

```sh
docker-compose exec --user app app php8 /var/www/html/tt-rss/update.php --help

#                           ^   ^
#                           |   |
#                           |   +- service (container) name
#                           +----- run as user
```

or

```sh
docker-compose exec app sudo -Eu app php8 /var/www/html/tt-rss/update.php --help
```

or

```sh
docker exec -it <container_id> sudo -Eu app php8 /var/www/html/tt-rss/update.php --help
```

Note: `sudo -E` is needed to keep environment variables.

### How do I add plugins and themes?

!!! notice

    First party plugins can be added using plugin installer in `Preferences` &rarr; `Plugins`.

By default, tt-rss code is stored on a persistent docker volume (``app``). You can find
its location like this:

```sh
docker volume inspect ttrss-docker_app | grep Mountpoint
```

Alternatively, you can mount any host directory as ``/var/www/html`` by updating ``docker-compose.yml``, i.e.:

```yml
volumes:
      - app:/var/www/html
```

Replace with:

```yml
volumes:
      - /opt/tt-rss:/var/www/html
```

Copy and/or git clone any third party plugins into ``plugins.local`` as usual.

### I'm running into 502 errors and/or other connectivity issues

First, check that all containers are running:

```
$ docker-compose ps
                   Name                                 Command               State           Ports
------------------------------------------------------------------------------------------------------------
ttrss-docker-demo_app_1_f49351cb24ed         /bin/sh -c /startup.sh           Up      9000/tcp
ttrss-docker-demo_backups_1_8d2aa404e31a     /dcron.sh -f                     Up      9000/tcp
ttrss-docker-demo_db_1_fc1a842fe245          docker-entrypoint.sh postgres    Up      5432/tcp
ttrss-docker-demo_updater_1_b7fcc8f20419     /updater.sh                      Up      9000/tcp
ttrss-docker-demo_web-nginx_1_fcef07eb5c55   /docker-entrypoint.sh ngin ...   Up      127.0.0.1:8280->80/tcp
```

Then, ensure that frontend (`web-nginx` or `web`) container is up and can contact FPM (`app`) container:

```
$ docker-compose exec web-nginx ping app
PING app (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.144 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.128 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.206 ms
^C
--- app ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.128/0.159/0.206 ms
```

Containers communicate via DNS names assigned by Docker based on service names defined in `docker-compose.yml`. This means that services (specifically, `app`) and Docker DNS service should be functional.

Similar issues may be also caused by Docker `iptables` functionality either being disabled or conflicting with `nftables`.

### I want to rename `app` (FPM) container

You can but you'll need to pass `APP_UPSTREAM` environment variable to the `web-nginx` container with its new name.

### How do I put this container behind a reverse proxy?

- Don't forget to pass `X-Forwarded-Proto` to the container if you're using HTTPS, otherwise tt-rss would generate plain HTTP URLs.
- Upstream address and port are set using `HTTP_PORT` in `.env`:

```ini
HTTP_PORT=127.0.0.1:8280
```

#### Nginx example

```nginx
location /tt-rss/ {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_pass http://127.0.0.1:8280/tt-rss/;
    break;
}
```

If you run into problems with global PHP-to-FPM handler taking priority over proxied location, define tt-rss location like this so it takes higher priority:

```nginx
location ^~ /tt-rss/ {
   ....
}
```

If you want to pass an entire nginx virtual host to tt-rss:

```nginx
server {
   server_name rss.example.com;

   ...

   location / {
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $remote_addr;
      proxy_set_header X-Forwarded-Proto $scheme;

      proxy_pass http://127.0.0.1:8280/;
      break;
   }
}
```

Note that `proxy_pass` in this example points to container website root.

#### Apache example

```
<IfModule mod_proxy.c>
    <Location /tt-rss>
      ProxyPreserveHost On
      ProxyPass        http://localhost:8280/tt-rss
      ProxyPassReverse http://localhost:8280/tt-rss
      RequestHeader set "X-Forwarded-Proto" expr=%{REQUEST_SCHEME}
    </Location>
  </IfModule>
```

### I have internal web services tt-rss is complaining about (URL is invalid, loopback address, disallowed ports)

Put your local services on the same docker network with tt-rss, then access them by service (= host) names, i.e. `http://rss-bridge/`.

```yml
services:
   rss-bridge:
....
networks:
  default:
    external:
      name: ttrss-docker_default
```

If your service uses a non-standard (i.e. not 80 or 443) port, make an internal reverse proxy sidecar container for it.

See also:

- https://community.tt-rss.org/t/heads-up-several-vulnerabilities-fixed/3799/
- https://community.tt-rss.org/t/got-specified-url-seems-to-be-invalid-when-subscribing-to-an-internal-rss-feed/4024

### Backup and restore

If you have `backups` container enabled, stock configuration makes automatic backups (database, local plugins, etc.) once a week to a separate storage volume.

Note that this container is included as a safety net for people who wouldn't bother with backups otherwise. If you value your data, you should invest your time into setting up something like [WAL-G](https://github.com/wal-g/wal-g) instead.

#### Restoring backups

A process to restore the database from such backup would look like this:

1. Enter `backups` container shell: `docker-compose exec backups /bin/sh`
2. Inside the container, locate and choose the backup file: `ls -t /backups/*.sql.gz`
3. Clear database (**THIS WOULD DELETE EVERYTHING IN THE DB**): `psql -h db -U $TTRSS_DB_USER $TTRSS_DB_NAME -e -c "drop schema public cascade; create schema public"`
3. Restore the backup: `zcat /backups/ttrss-backup-yyyymmdd.sql.gz | psql -h db -U $TTRSS_DB_USER $TTRSS_DB_NAME`

Alternatively, if you want to initiate backups from the host, you can use something like this:

```sh
source .env
docker-compose exec db /bin/bash \
  -c "export PGPASSWORD=$TTRSS_DB_PASS \
  && pg_dump -U $TTRSS_DB_USER $TTRSS_DB_NAME" \
  | gzip -9 > backup.sql.gz
```

([source](https://community.tt-rss.org/t/docker-compose-tt-rss/2894/233?u=fox))

### How do I use custom certificates?

You need to mount custom certificates into the *app* and *updater* containers like this:

```yml
volumes:
    ....
    ./ca1.crt:/usr/local/share/ca-certificates/ca1.crt:ro
    ./ca2.crt:/usr/local/share/ca-certificates/ca2.crt:ro
    ....
```

Don't forget to restart the containers.

See also: https://community.tt-rss.org/t/60-ssl-certificate-problem-unable-to-get-local-issuer-certificate/4838/4?u=fox

### How do I run these images on K8S?

You'll need to set several mandatory environment values to the container running web-nginx image:

1. `APP_UPSTREAM` should point to the fully-qualified DNS service name provided by the app (FPM) container/pod;
2. `RESOLVER` should be set to `kube-dns.kube-system.svc.cluster.local`

Link to discussion with examples: https://community.tt-rss.org/t/resolving-issues-with-latest-commit-on-k8s/6208/7 and below

### Where's the helm chart?

I don't provide one. You will have to make your own.

### I'm using Podman, and...

I neither test against nor support Podman. Please don't report any issues when using it.
