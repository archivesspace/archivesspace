require 'thread'
require 'atomic'
require_relative 'batch_import_runner'


class BatchImportJobQueue

  JOB_TIMEOUT_SECONDS = 120

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

    $stderr.puts("RUNNING JOB: #{job.inspect}")

    return if !job

    finished = Atomic.new(false)

    watchdog_thread = Thread.new do
      while !finished.value
        DB.open do
          $stderr.puts("Setting MTIME")
          ImportJob.any_repo[job.id].save
        end

        sleep 5
      end
    end

    begin
      BatchImportRunner.new(job).run

      finished.value = true
      watchdog_thread.join

      job.reload
      job.status = "completed"
      job.time_finished = Time.now
      job.save
    rescue
      Log.error("Job #{job.id} failed: #{$!} #{$@}")
      # If anything went wrong, make sure the watchdog thread still stops.
      finished.value = true
      watchdog_thread.join

      job.reload
      job.status = "failed"
      job.time_finished = Time.now
      job.save
    end

    $stderr.puts("All done!")
  end


  def start_background_thread
    Thread.new do
      while true
        begin
          run_pending_import
        rescue
          Log.error("Error in batch import thread: #{$!} #{$@}")
        end

        # FIXME: Configurable?
        sleep 5
      end
    end
  end


  def self.init
    importer = BatchImportJobQueue.new
    importer.start_background_thread
  end

end
