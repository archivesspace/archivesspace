# This is actually a big bunch of nothing. 
# We run this job in the conversation process
class ContainerConversionRunner < JobRunner

  def self.instance_for(job)
    if job.job_type == "container_conversion_job"
      self.new(job)
    else
      nil
    end
  end


  def run
    super
  end

end
