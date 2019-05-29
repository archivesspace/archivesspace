---
title: ArchivesSpace robots.txt
layout: en
permalink: /user/archivesspace-robots.txt/
---
The easiest way to add a `robots.txt` to your site is simply create
one in your `/config/` directly. This file will be served as a standard 
`robots.txt` file when you start your site.

If you're not able to do that, you can use a seperate file and your proxy.

For Apache the config would look like this:

```
<Location "/robots.txt">
 SetHandler None
 Require all granted
</Location>
Alias /robots.txt /var/www/robots.txt
```

nginx, more like this:

```
  location /robots.txt {
    alias /var/www/robots.txt;
  }
```

You may also add robots meta-tags to your `layout_head.html.erb` to be included in the header area of your site.

example:

`<meta name="robots" content="noindex, nofollow">`

A sensible starting point for a `robots.txt` file looks something like this:

```
Disallow: /search*
Disallow: /inventory/*
Disallow: /collection_organization/*
Disallow: /repositories/*/top_containers/*
Disallow: /check_session*
Disallow: /repositories/*/resources/*/tree/*
```
