class JobRunner

  class JobRunnerNotFound < StandardError; end
  class JobRunnerError < StandardError; end
  class BackgroundJobError < StandardError; end


  # Implement this in your subclass
  #
  # This returns an instance of the subclass if the job
  # has a job_type that the subclass knows how to run,
  # otherwise is returns nil
  def self.instance_for(job)
    # Not raising here because we don't want one bad runner to spoil it for everyone
    return nil

    # Example:
    # if job.job_type == "my_job_type"
    #   self.new(job)
    # else
    #   nil
    # end
  end


  # Implement this in your subclass
  #
  # This is the method that does the actual work
  def run
    raise JobRunnerError.new("#{self.class} must implement the #run method")
  end


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


  def canceled?
    @job_canceled.value
  end


  def cancelation_signaler(canceled)
    @job_canceled = canceled
  end

end
