# Work through the list of import jobs in the database and run the next job in
# the queue.

require 'thread'
require 'atomic'
require_relative 'job_runner'
require_relative 'find_and_replace_runner'
require_relative 'print_to_pdf_runner'
require_relative 'reports_runner'
require_relative 'batch_import_runner'
require_relative 'container_conversion_runner'

class BackgroundJobQueue

  JOB_TIMEOUT_SECONDS = AppConfig[:job_timeout_seconds].to_i

  def find_stale_job
    DB.open do |db|
      stale_job = Job.any_repo.
        filter(:status => "running").
        where {
        system_mtime <= (Time.now - JOB_TIMEOUT_SECONDS)
      }.first 

      if stale_job
        begin
          stale_job.time_started = Time.now
          stale_job.save
          return stale_job
        rescue
          # If we failed to save the job, another thread must have grabbed it
          # first.
          nil
        end
      end
    end
  end


  def find_queued_job
    while true
      DB.open do |db|

        job = Job.any_repo.
          filter(:status => "queued").
          order(:time_submitted).first

        return unless job

        begin
          job.status = "running"
          job.time_started = Time.now
          job.save

          return job
        rescue
          # Someone got this job.
          Log.info("Skipped job: #{job}")
          sleep 2
        end
      end
    end
  end


  def get_next_job
    find_stale_job || find_queued_job
  end


  def run_pending_job
    job = get_next_job

    return if !job

    finished = Atomic.new(false)
    job_canceled = Atomic.new(false)

    watchdog_thread = Thread.new do
      while !finished.value
        DB.open do |db|
          Log.debug("Running job #{job.class.to_s}:#{job.id}")
          job = job.class.any_repo[job.id]

          if job.status === "canceled"
            # Notify the running import that we've been manually canceled
            Log.info("Received cancel request for job #{job.id}")
            job_canceled.value = true
          end

          job.update_mtime
        end

        sleep [5, (JOB_TIMEOUT_SECONDS / 2)].min
      end
    end

    begin
      runner = JobRunner.for(job).canceled(job_canceled)
      runner.add_success_hook do
        # Upon success, have the job set our status to "completed" at the right
        # point.  This allows the batch import to set the job status within the
        # same DB transaction that handled the import (avoiding a situation
        # where the import completes and commits, but the job status update
        # fails separately)
        #
        finished.value = true
        watchdog_thread.join

        job.finish(:completed)
      end

      runner.run

      finished.value = true
      watchdog_thread.join

      if job_canceled.value
        # Mark the job as permanently canceled
        job.finish(:canceled)
      else
        unless job.success?
          # If the job didn't record success, mark it as finished ourselves.
          # This isn't really a problem, but it does mean that the job status
          # update is now happening in a separate DB transaction than the one
          # that ran the job.  If the system crashed after the job finished but
          # prior to this point, the job might have finished successfully
          # without being recorded as such.
          #
          Log.warn("Job #{job.id} finished successfully but didn't report success.  Marking it as finished successfully ourselves.")
          runner.success!
        end
      end
    rescue
      Log.error("Job #{job.id} failed: #{$!} #{$@}")
      # If anything went wrong, make sure the watchdog thread still stops.
      finished.value = true
      watchdog_thread.join

      unless job.success?
        job.finish(:failed)
      end
    end

    Log.debug("Completed job #{job.class.to_s}:#{job.id}")
  end


  def start_background_thread(thread_number)
    Thread.new do
      Thread.current[:number] = thread_number
      Log.info("Starting background job thread #{Thread.current[:number]}")
      while true
        begin
          run_pending_job
        rescue
          Log.error("Error in job manager thread #{Thread.current[:number]}: #{$!} #{$@}")
        end

        sleep AppConfig[:job_poll_seconds].to_i
      end
    end
  end


  def start_background_threads
    AppConfig[:job_thread_count].times do |i|
      start_background_thread(i+1)
    end
  end


  def self.init
    # clear out stale jobs on start
    begin
      while(true) do
        stale = find_stale_job
        stale.finish(:canceled)
        break if stale.nil?
      end
    rescue
    end
    

    queue = BackgroundJobQueue.new
    queue.start_background_threads
  end

end
