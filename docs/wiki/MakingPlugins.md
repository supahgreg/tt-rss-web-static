# Making Plugins

Plugins may render new preference panes or embed themselves into several
existing one, store data using simple key -\> value data or directly in
the database, modify how articles are rendered, alter feed data, and
much more.

You can use sample plugins bundled with tt-rss and [other
plugins](../Plugins.md) as a starting point. Ask on the forums if you need help
with anything specific.

WIP: Auto-generated API reference is available here:

- https://srv.tt-rss.org/ttrss-docs/classes/PluginHost.html
- https://srv.tt-rss.org/ttrss-docs/classes/Plugin.html

Frontend (JS) uses different hooks, defined in <code>js/PluginHost.js</code>.

A few more example plugins are available in the [samples](https://gitlab.tt-rss.org/tt-rss/tt-rss-samples) repository.

## Localization support

See ``time_to_read`` plugin for a complete example [here](https://gitlab.tt-rss.org/tt-rss/plugins/ttrss-time-to-read)

### Implementation

- Plugin translations are placed in a separate Gettext domain (name equals lowercase plugin class).
- Translation (.po) file in ``(plugin dir)/locale/(LANG)/LC_MESSAGES/`` name should correspond to Gettext domain name.

### Using gettext

- On the PHP side, either use helper methods defined in ``classes/plugin.php``
  (base class for all plugins) or call ``_dgettext`` group of functions
  directly.
- On the Javascript side, all translations are merged so you can use the usual
  ``__()`` shortcut function.

