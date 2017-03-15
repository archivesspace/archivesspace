ArchivesSpace Public Demo pugin
===============

This is an example plugin for the ArchivesSpace public interface
to demonstrate the various plugin hooks.

It will add pugs.

## Getting Started

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'public_demo_pugin']

This plugin is only compatible with the new public interface
and assumes the environment variable `ASPACE_PUBLIC_NEW` is set:

    ENV['ASPACE_PUBLIC_NEW'] = 'true'