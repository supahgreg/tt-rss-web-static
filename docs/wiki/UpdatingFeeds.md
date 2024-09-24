# Updating Feeds

- ***Host installations are not supported starting 2021. Consider using [Docker](InstallationNotes.md) when planning new tt-rss installations.***
- *The following applies to host installations only, updates are handled out of the box if using recommended [dockerized setup](https://git.tt-rss.org/fox/ttrss-docker-compose).*
- *This document is considered deprecated.*

------

You **have** to setup one of this methods before you can start using tt-rss
properly, otherwise your feeds won’t be updated.

Run update daemon if you are allowed to run background processes on your
tt-rss machine. Otherwise, use one of the other methods. Third party packages
and Docker containers usually have some way of updating built-in.

## Update daemon

**This is the recommended way to update feeds**. Please use it if you
have access to PHP command line interpreter and can run background processes. You
can run single-process update daemon or update\_daemon2.php
(multi-process, runs several update tasks in parallel) using PHP CLI
interpreter. Do not use PHP CGI binary to run command line scripts.

Please do not ever run update daemon or any PHP processes as root. It is
recommended, but not required, to run the daemon under your website user
id (usually www-data, apache or something like that) to prevent file
ownership issues.

Run: <code>php ./update.php --daemon</code> (single process) or <code>php ./update\_daemon2.php</code> (multi-process)

Script doesn’t daemonize (e.g. detach from the terminal).

### Running under systemd

You can setup the daemon as a simple systemd service like this (`/etc/systemd/system/ttrss_backend.service`):

```ini
[Unit]
Description=ttrss_backend
After=network.target mysql.service postgresql.service

[Service]
User=www-data
ExecStart=/var/www/html/tt-rss/update_daemon2.php

[Install]
WantedBy=multi-user.target
```

```sh
systemctl enable ttrss_backend
systemctl start ttrss_backend
```

Use <code>journalctl -u ttrss_backend</code> to look through daemon console output.

## Periodical updating from crontab, using update script (update.php --feeds)

Use this if you have access to PHP command line interpreter but not
allowed (e.g. by your hosting provider) to run persistent background
processes. Do not try to run cronjobs with a PHP CGI binary, it’s not
going to work. If you see HTTP headers being displayed when you run
<code>php ./update.php</code> you are using an incorrect binary.

Full example (see man 5 crontab for more information on the syntax):

    */30 * * * * /usr/bin/php /path/to/tt-rss/update.php --feeds --quiet

Notes:

-   <code>/usr/bin/php</code> should be replaced with the correct path
    to PHP CLI binary on your system. If you are not sure which binary
    or what path to use, ask your hosting provider.
-   Try the command using shell if possible to check if it works before
    setting up the cronjob.

## Simple background updates

If all else fails and you can’t use any of the above methods, you can
enable simple update mode where tt-rss will try to periodically update
feeds while it is open in your web browser. Obviously, no updates will
happen when tt-rss is not open or your computer is not running.

To enable this mode, set constant <code>SIMPLE\_UPDATE\_MODE</code> to
<code>true</code> in <code>config.php</code>.

Note that only main tt-rss UI supports this, if you have digest or
mobile open or use an API client (for example, android application),
feeds are not going to be updated. You absolutely have to have tt-rss
open in a browser tab on a running computer somewhere.
