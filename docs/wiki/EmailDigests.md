# Email Digests

Users may opt into receiving daily (sent once every 24 hours) digests of unread headlines via email.

Digests are sent out by the update daemon or if running <code>update.php —feeds</code>
manually. At most 15 messages are sent in one batch.

!!! notice

    [PHPMailer plugin](https://git.tt-rss.org/fox/ttrss-mailer-smtp) is required to send mail under Docker.


* Digests may be customized by editing ``templates/digest_template*.txt``.
* You can preview your digest contents in preferences.

