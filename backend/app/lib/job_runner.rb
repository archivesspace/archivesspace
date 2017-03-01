class JobRunner

  class JobRunnerNotFound < StandardError; end
  class JobRunnerError < StandardError; end
  class BackgroundJobError < StandardError; end


  # In your subclass register your interest in handling job types like this:
  #
  #   class MyRunner < JobRunner
  #     register_for_job_type('my_job')
  #     ...
  #
  # This can be called many times if your runner can handle ore than one job type.
  # The type is the jsonmodel_type of the defined schema for the job type.
  #
  # If another runner has already registered for the type an exception will be thrown.
  #
  # The register_for_job_type method can take two options:
  #   register_for_job_type('my_job', :hidden => true, :run_concurrently => true)
  #
  #   :hidden - if true then the job_type is not included in the list of job_types
  #   :run_concurrently - if true then jobs of this type will be run concurrently
  #
  # Both options are false by default.


  # Implement this in your subclass
  #
  # This is the method that does the actual work
  def run
    raise JobRunnerError.new("#{self.class} must implement the #run method")
  end


  # Nothing below here needs to be implemented in your subclass


  def self.register_for_job_type(type, opts = {})
    @@runners ||= {}
    if @@runners.has_key?(type)
      raise JobRunnerError.new("Attempting to register #{self} for job type #{type} " +
                               "- already handled by #{@@runners[type]}")
    end

    @@runners[type] = {
      :class => self,
      :hidden => opts.fetch(:hidden, false),
      :run_concurrently => opts.fetch(:run_concurrently, false)
    }
  end


  def self.for(job)
    type = ASUtils.json_parse(job[:job_blob])['jsonmodel_type']

    unless @@runners.has_key?(type)
      raise JobRunnerNotFound.new("No suitable runner found for #{type}")
    end

    @@runners[type][:class].new(job)
  end


  def self.registered_job_types
    @@runners.keys.select {|k| !@@runners[k][:hidden] }
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
