Background Jobs
==============

ArchivesSpace provides a mechanism for long running processes to run asynchronously. These processes are called `Background Jobs`.

## Managing Jobs in the Staff UI

The `Create` menu has a `Background Job` option which shows a submenu of job types that the current user has permission to create. (See below for more information about job permissions and hidden jobs.) Selecting one of these options will take the user to a form to enter any parameters required for the job and then to create it.

When a job is created it is placed in the `Background Job Queue`. Jobs in the queue will be run in the order they were created. (See below for more information about multiple threads and concurrent jobs.)

The `Browse` menu has a `Background Jobs` option. This takes the user to a list of jobs arranged by their status. The user can then view the details of a job, and cancel it if they have permission.


## Permissions

A user must have the `create_job` permission to create a job. By default, this permission is included in the `repository_basic_data_entry` group.

A user must have the `cancel_job` permission to cancel a job. By default, this permission is included in the `repository_managers` group.

When a JobRunner registers it can specify additional create and cancel permssions. (See below for more information)


## Types, Runners and Schemas

Each job has a type, and each type has a registered runner to run jobs of that type and JSONModel schema to define its parameters.

#### Registered JobRunners

All jobs of a type are handled by a registered `JobRunner`. The job runner classes are located here:

      backend/app/lib/job_runners/

It is possible to define additional job runners from a plugin. (See below for more information about plugins.)

A job runner class must subclass `JobRunner`, reigister to run one or more job types, and implement a `#run` method for jobs that it handles.

When a job runner registers for a job type, it can set some options:

  * `:hidden`
      * Defaults to `false`
      * If this is set then this job type will not be shown in the list of available job types.
  * `:run_concurrently`
      * Defaults to `false`
      * If this is set to true then more than one job of this type can run at the same time.
  * `:create_permissions`
      * Defaults to `[]`
      * A permission or list of permissions required, in addition to `create_job`, to create jobs of this type.
  * `:cancel_permissions`
      * Defaults to `[]`
      * A permission or list of permissions required, in addition to `cancel_job`, to cancel jobs of this type.

For more information about defining a job runner, see the `JobRunner` superclass:

      backend/app/lib/job_runner.rb

#### JSONModel Schemas

A job type also requires a JSONModel schema that defines the parameters to run a job of the type. The schema name must be the same as the type that the runner registers for. For example:

      common/schemas/import_job.rb

This schema, for `JSONModel(:import_job)`, defines the parameters for running a job of type `import_job`.


## Concurrency

ArchivesSpace can be configured to run more than one background job at a time. By default, there will be two threads available to run background jobs. The configuration looks like this:

      AppConfig[:job_thread_count] = 2

The `BackgroundJobQueue` will start this number of threads at start up. Those threads will then poll for queued jobs and run them.

When a job runner registers, it can set an option called `:run_concurrently`. This is `false` by default. When set to `false` a job thread will not run a job if there is already a job of that type running. The job will remain on the queue and will be run when there are no longer any jobs of its type running.

When set to `true` a job will be run when it comes to the front of the queue regardless of whether there is a job of the same type running.


## Plugins

It is possible to add a new job type from a plugin. ArchivesSpace includes a plugin that demonstrates how to do this:

      plugins/jobs_example

