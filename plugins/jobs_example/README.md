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

It is intended to demonstrate implementation for adding a job
type from a plugin.

## Files included
- **frontend/views/slow_nothing_job/\_form.html.erb**: This is
an example of how to create a form for your job which you will
need to do if your job requires any parameters
- **frontend/assets/javascripts/slow_nothing.js**: Gives an
example of how to apply javascript to your job form in case it
has any moving elements
- **backend/job_runners/slow_nothing_runner.rb**: Implements the
functionality of the job in the run method

## Changes for v2.6.0 and up
Prior to v2.6.0 form inputs parameters specific to a job type
were named as follows:

*name_of_job_type*\_job[*name_of_parameter*]

For v2.6.0 and up they must instead be named as follows:

job[*name_of_parameter*]

If you used the form helper methods (i.e. something like
  form.label_and_textfield) to create the form inputs then this
  change should not affect you. However, if this is not the
  case you will need to update \_form.html.erb in order for
  your existing background job plugins to work with v2.6.0
  and above.
