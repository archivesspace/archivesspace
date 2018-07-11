ArchivesSpace jobs_example plugin
=================================

This is an example plugin for adding a background job type.

## Getting Started

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'jobs_example']


## What does it do?

It adds a new kind of job called `slow_nothing_job`. It doesn't
do anything except sleep for 10 seconds a parameterizable number
of times, and log the fact. It can also be canceled, and can
report its success.

It is intended to demonstrate a minimal implementation for
adding a job type from a plugin.

