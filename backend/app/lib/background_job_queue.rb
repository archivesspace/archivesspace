# Work through the list of import jobs in the database and run the next job in
# the queue.

require 'thread'
require 'atomic'
require_relative 'job_runner'
require_relative 'find_and_replace_runner'
require_relative 'print_to_pdf_runner'
require_relative 'reports_runner'
require_relative 'batch_import_runner'


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
        DB.open do
          Log.debug("Running job #{job.class.to_s}:#{job.id}")
          job = job.class.any_repo[job.id]

          if job.status === "canceled"
            # Notify the running import that we've been manually canceled
            Log.info("Received cancel request for job #{job.id}")
            job_canceled.value = true
          end

          job.save
        end

        sleep [5, (JOB_TIMEOUT_SECONDS / 2)].min
      end
    end

    begin
      runner = JobRunner.for(job).canceled(job_canceled)
      runner.run

      finished.value = true
      watchdog_thread.join

      if job_canceled.value
        job.finish(:canceled)
      else
        job.finish(:completed)
      end

    rescue
      Log.error("Job #{job.id} failed: #{$!} #{$@}")
      # If anything went wrong, make sure the watchdog thread still stops.
      finished.value = true
      watchdog_thread.join

      job.finish(:failed)
    end

    Log.debug("Completed job #{job.class.to_s}:#{job.id}")
  end


  def start_background_thread
    Thread.new do
      while true
        begin
          run_pending_job
        rescue
          Log.error("Error in job manager thread: #{$!} #{$@}")
        end

        sleep AppConfig[:job_poll_seconds].to_i
      end
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
    queue.start_background_thread
  end

end
