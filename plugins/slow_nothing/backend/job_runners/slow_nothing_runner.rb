class SlowNothingRunner < JobRunner

  register_for_job_type('slow_nothing_job', :run_concurrently => false)

  def run
    @json.job['times'].to_i.times do |i|
      if self.canceled?
        log("Oh gee, I've been canceled")
        break
      end
      log("I did something!!! #{i+1}")
      sleep 10
    end
    log("Phew, I'm done doing nothing!")
    self.success!
  end

  def log(s)
    Log.debug(s)
    @job.write_output(s)
  end

end
