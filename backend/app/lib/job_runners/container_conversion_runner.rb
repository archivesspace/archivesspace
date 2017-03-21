# This is actually a big bunch of nothing. 
# We run this job in the conversation process
class ContainerConversionRunner < JobRunner

  register_for_job_type('container_conversion_job',
                        :hidden => true,
                        :create_permissions => :administer_system,
                        :cancel_permissions => :administer_system)


  def run
    # nothing
  end

end
