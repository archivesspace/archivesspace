class JobRunner

  class JobRunnerNotFound < StandardError; end

  def self.for(job)
    @runners.each do |runner|
      runner = runner.instance_for(job)
      return runner if runner
    end

    raise JobRunnerNotFound.new("No suitable runner found for #{job.job_type}")
  end


  def self.register_runner(subclass)
    @runners ||= []
    @runners.unshift(subclass)
  end


  def self.inherited(subclass)
    JobRunner.register_runner(subclass)
  end


  def canceled(canceled)
    @job_canceled = canceled
    self
  end


  def run; end

end
