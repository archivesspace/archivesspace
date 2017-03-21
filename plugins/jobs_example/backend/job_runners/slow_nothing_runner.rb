require 'java'
import java.lang.management.ManagementFactory

class SlowNothingRunner < JobRunner

  register_for_job_type('slow_nothing_job', :run_concurrently => true)

  def run
    @json.job['times'].to_i.times do |i|
      if self.canceled?
        log("Oh gee, I've been canceled")
        break
      end

      memory = ManagementFactory.memory_mx_bean
      log("#{i+1} of #{@json.job['times']}")
      log(Time.now)
      log("Heap:            #{memory.heap_memory_usage}")
      log("Non-heap:        #{memory.non_heap_memory_usage}")
      log("Finalize count:  #{memory.object_pending_finalization_count}")
      log("===")
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
