# Installing on a host machine

!!! warning

    Host installations are not supported starting 2021. Consider using [Docker](InstallationNotes.md) when planning new tt-rss installations.

    This document is considered deprecated. Information here may be obsolete and/or inaccurate.

Before you begin, you’ll need the following:

 - Access to shared hosting or a dedicated server running a http server (preferably with SSL)
 - PHP, at least version 7.1, with several dependencies (I suggest checking `.docker/app/Dockerfile` for the list)
 - A database (PostgreSQL or MySQL/MariaDB) server credentials (login, password, hostname)
 - Basic knowledge of Git, which should be available on your server/hosting

#### Host installation overview

Clone tt-rss repository using Git. Always use latest Git code from master branch.

```
git clone https://git.tt-rss.org/fox/tt-rss.git tt-rss
```

Alternatively, you can clone the repository on your local machine and upload files using FTP/rsync or any other means available to
you.

Deal with [global configuration](GlobalConfig.md) in `config.php`:

- Copy `config.php-dist` to `config.php`
- Define mandatory global settings below and any other you need changed. This is the absolute minimum required to be set (for PostgreSQL):

```sh
putenv('TTRSS_DB_HOST=dbhost');
putenv('TTRSS_DB_NAME=dbname');
putenv('TTRSS_DB_USER=dbuser');
putenv('TTRSS_DB_PASS=dbpassword');
putenv('TTRSS_SELF_URL_PATH=https://example.com/tt-rss');
```

In case of MySQL/MariaDB, add the following:

```sh
putenv('TTRSS_DB_TYPE=mysql');
putenv('TTRSS_DB_PORT=3306');
```

Then, install base database schema. In tt-rss directory, run the following:

```
php ./update.php --update-schema
```

Open your tt-rss installation and login with default credentials (username: <code>admin</code>, password: <code>password</code>).

**Don't forget to change the password!**

Configure feed updates. This is a separate topic, explained in [UpdatingFeeds](UpdatingFeeds.md) wiki page. Please read it, otherwise your feeds won't get updated.

If all went well, proceed to use tt-rss normally. Create a separate non-admin user, login under it, and start importing your feeds,
subscribing, etc.

See also: [SecuringCacheDirectories](SecuringCacheDirectories.md)

#### Take a look at available plugins

There are many plugins written for tt-rss. You can see the list here: [Plugins](../Plugins.md).

-----

## Upgrading Tiny Tiny RSS

- Change to tt-rss directory on your server and run ``git pull origin master``
- Update the database via CLI: `php ./update.php --update-schema` or open tt-rss in the web browser (you will be redirected to the database updater if needed

#### Optional post-upgrade tasks

- You might need to clear your browser cache if you experience CSS or script-related issues
- Log in in safe mode if there are any plugin or theme-related issues after upgrade
- If you are using an accelerator like php-apc you might need to restart apache if older cached versions of PHP files got stuck in the (misconfigured) cache.
