# Search Syntax

!!! notice

    This only applies to built-in search, plugins like ``sphinx_search`` may override this syntax.

Search query consists of several keywords. Keyword starting with "-" is
considered a negative match. Several special keywords are available:

* ``@{date}`` - match by date. For example, @yesterday or @2011-11-03. Please note that due to incomplete implementation, special date keywords like yesterday might not match all articles if user timezone is different from tt-rss internal timezone (UTC).
* ``pub:{true,false}`` - match only published or unpublished articles
* ``star:{true, false}`` - same, starred articles
* ``unread:{true, false}`` - self explanatory (requires trunk as of 05.03.2015)
* ``note:{true, false, sometext}`` - same, for articles having an attached note or matching the specified text
* ``label:Somelabel`` - articles that belong to a specified label
* ``title:``, ``author:`` - self explanatory

Pointless as it may be, you can combine negative prefix with the special
keywords: -star:true would essentially mean star:false.
