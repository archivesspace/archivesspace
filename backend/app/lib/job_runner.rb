class JobRunner

  class JobRunnerNotFound < StandardError; end

  class BackgroundJobError < StandardError; end

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


  def initialize(job)
    @job = job
    RequestContext.open(:repo_id => @job.repo_id) do
      @json = Job.to_jsonmodel(job)
    end
  end


  def add_success_hook(&block)
    @success_hooks ||= []
    @success_hooks << block
  end


  def success!
    Array(@success_hooks).each do |hook|
      hook.call
    end
  end


  def canceled(canceled)
    @job_canceled = canceled
    self
  end


  def run; end

end
