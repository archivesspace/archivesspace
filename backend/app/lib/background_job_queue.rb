# Work through the list of import jobs in the database and run the next job in
# the queue.

require 'thread'
require 'atomic'

require_relative 'job_runner'

# load job runners
Dir.glob(File.join(File.dirname(__FILE__), "job_runners", "*.rb")).sort.each do |file|
  require file
end

# and also from plugins
ASUtils.find_local_directories('backend').each do |prefix|
  Dir.glob(File.join(prefix, "job_runners", "*.rb")).sort.each do |file|
    require File.absolute_path(file)
  end
end


class BackgroundJobQueue

  JOB_TIMEOUT_SECONDS = AppConfig[:job_timeout_seconds].to_i

  def get_next_job
    # First cancel any jobs that are in a running state but which haven't
    # been touched by their watchdog for a time greater than the configured timeout.
    # This shouldn't really happen, but his replaces the concept of a stale job
    # used in an earlier implementation that was problematic because it could end up
    # calling the #run method on a job more than once.
    begin
      Job.running_jobs_untouched_since(Time.now - JOB_TIMEOUT_SECONDS).each do |job|
        job.finish!(:canceled)
      end
    rescue Sequel::NoExistingObject
      Log.debug("Another thread cancelled unwatched job #{job.id}, nothing to do on #{Thread.current[:name]}")
    rescue => e
      Log.error("Error trying to cancel unwatched jobs on #{Thread.current[:name]}: #{e.class} #{$!} #{$@}")
    end

    DB.open do |db|
      Job.queued_jobs.each do |job|
        runner = JobRunner.registered_runner_for(job.type)

        begin
          unless runner
            Log.error("No runner registered for #{job.type} job #{job.id}! " +
                      "Marking as canceled on #{Thread.current[:name]}")

            job.finish!(:canceled)
            next
          end

          if !runner.run_concurrently && Job.any_running?(job.type)
            Log.debug("Job type #{job.type} is not registered to run concurrently " +
                      "and there's currently one running, so skipping job #{job.id} " +
                      "on #{Thread.current[:name]}")
            next
          end

          # start the job here to prevent other threads from grabbing it
          job.start!

          return job

        rescue Sequel::NoExistingObject
          # Another thread handled this job.
          Log.info("Another thread is handling job #{job.id}, skipping on #{Thread.current[:name]}")
        end
      end
    end
    # No jobs to run at this time
    false
  end


  def run_pending_job
    job = get_next_job

    return if !job

    finished = Atomic.new(false)
    job_canceled = Atomic.new(false)
    job_thread_name = Thread.current[:name]

    watchdog_thread = Thread.new do
      while !finished.value
        DB.open do |db|
          Log.debug("Running job #{job.id} on #{job_thread_name}")
          job = job.class.any_repo[job.id]

          if job.status === "canceled"
            # Notify the running job that we've been manually canceled
            Log.info("Received cancel request for job #{job.id} on #{job_thread_name}")
            job_canceled.value = true
          end

          job.update_mtime
        end

        sleep [5, (JOB_TIMEOUT_SECONDS / 2)].min
      end
    end

    begin
      runner = JobRunner.for(job)

      # Give the runner a ref to the canceled atomic,
      # so it can find out if it's been canceled
      runner.cancelation_signaler(job_canceled)

      runner.add_success_hook do
        # Upon success, have the job set our status to "completed" at the right
        # point.  This allows the batch import to set the job status within the
        # same DB transaction that handled the import (avoiding a situation
        # where the import completes and commits, but the job status update
        # fails separately)
        #
        finished.value = true
        watchdog_thread.join

        job.finish!(:completed)
      end

      runner.run

      finished.value = true
      watchdog_thread.join

      if job_canceled.value
        # Mark the job as permanently canceled
        job.finish!(:canceled)
      else
        unless job.success?
          # If the job didn't record success, mark it as finished ourselves.
          # This isn't really a problem, but it does mean that the job status
          # update is now happening in a separate DB transaction than the one
          # that ran the job.  If the system crashed after the job finished but
          # prior to this point, the job might have finished successfully
          # without being recorded as such.
          #
          Log.warn("Job #{job.id} finished successfully but didn't report success.  " +
                   "Marking it as finished successfully ourselves, on #{job_thread_name}.")
          runner.success!
        end
      end
    rescue => e
      Log.error("Job #{job.id} on #{job_thread_name} failed: #{e.class} #{$!} #{$@}")
      # If anything went wrong, make sure the watchdog thread still stops.
      finished.value = true
      watchdog_thread.join

      unless job.success?
        job.finish!(:failed)
      end
    end

    Log.debug("Completed job #{job.id} on #{job_thread_name}")
  end


  def start_background_thread(thread_number)
    Thread.new do
      Thread.current[:name] = "background job thread #{thread_number} (#{Thread.current.object_id})"
      Log.info("Starting #{Thread.current[:name]}")
      while true
        begin
          run_pending_job
        rescue => e
          Log.error("Error in #{Thread.current[:name]}: #{e.class} #{$!} #{$@}")
        end
        sleep AppConfig[:job_poll_seconds].to_i
      end
    end
  end


  def start_background_threads
    AppConfig[:job_thread_count].to_i.times do |i|
      start_background_thread(i+1)
    end
  end


  def self.init
    # cancel jobs left in a running state from a previous run
    begin
      Job.running_jobs_untouched_since(Time.now - JOB_TIMEOUT_SECONDS).each do |job|
        job.finish!(:canceled)
      end
    rescue => e
      Log.error("Error trying to cancel old jobs: #{e.class} #{$!} #{$@}")
    end
    

    queue = BackgroundJobQueue.new
    queue.start_background_threads
  end

end
