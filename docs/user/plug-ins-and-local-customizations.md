---
title: Plug-ins and local customizations 
layout: en
permalink: /user/plug-ins-and-local-customizations/ 
---

Under your `archivesspace` directory there is a directory called `plugins`.
Each directory under the `plugins` directory contains a plug-in. In the
standard distribution there are several plug-in directories, including
`hello_world` and `local`. The `hello_world` directory contains a simple
exemplar plug-in. The `local` directory is empty - this is a place to put
any local customizations or extensions to ArchivesSpace without having to
change the core codebase.

Plug-ins are enabled by listing them in the configuration file. You will see the following line in
`config/config.rb`:

     # AppConfig[:plugins] = ['local']

This states that by default the `local` plug-in is enabled and any files
contained there will be loaded and available to the application. In order
to enable other plug-ins simply override this configuration in
`config/config.rb`. For example, to enable the `hello_world` plug-in, add
a line like this (ensuring you remove the `#` at the beginning of the line):

    AppConfig[:plugins] = ['local', 'hello_world']

Note that the string must be identical to the name of the directory under the
`plugins` directory. Also note that the ordering of plug-ins in the list
determines the order that the plug-ins will be loaded.

For more information about plug-ins and how to use them to override and
customize ArchivesSpace, please see the README in the `plugins` directory.


