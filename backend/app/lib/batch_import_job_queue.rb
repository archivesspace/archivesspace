# Work through the list of import jobs in the database and run the next job in
# the queue.

require 'thread'
require 'atomic'
require_relative 'batch_import_runner'


class BatchImportJobQueue

  JOB_TIMEOUT_SECONDS = AppConfig[:import_timeout_seconds].to_i


  def find_stale_job
    DB.open do |db|
      stale_job = ImportJob.any_repo.
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
        job = ImportJob.any_repo.
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


  def run_pending_import
    job = get_next_job

    return if !job

    finished = Atomic.new(false)
    import_canceled = Atomic.new(false)

    watchdog_thread = Thread.new do
      while !finished.value
        DB.open do
          Log.debug("Import running for job #{job.id}")
          job = ImportJob.any_repo[job.id]

          if job.status === "canceled"
            # Notify the running import that we've been manually canceled
            Log.info("Received cancel request for import job #{job.id}")
            import_canceled.value = true
          end

          job.save
        end

        sleep [5, (JOB_TIMEOUT_SECONDS / 2)].min
      end
    end

    begin
      BatchImportRunner.new(job, import_canceled).run

      finished.value = true
      watchdog_thread.join

      if import_canceled.value
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

    Log.debug("Import completed for job #{job.id}")
  end


  def start_background_thread
    Thread.new do
      while true
        begin
          run_pending_import
        rescue
          Log.error("Error in batch import thread: #{$!} #{$@}")
        end

        sleep AppConfig[:import_poll_seconds].to_i
      end
    end
  end


  def self.init
    importer = BatchImportJobQueue.new
    importer.start_background_thread
  end

end
