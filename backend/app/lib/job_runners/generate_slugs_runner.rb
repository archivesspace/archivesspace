class GenerateSlugsRunner < JobRunner

  register_for_job_type('generate_slugs_job',
                        {:create_permissions => :manage_repository,
                         :cancel_permissions => :manage_repository,
                         :allow_reregister => true})
  
  def run
    begin
      # REPOSITORIES
      @job.write_output("Generating slugs for Repositories")
      @job.write_output("================================")

      Repository.each do |r|
        @job.write_output("Generating slug for repository id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # RESOURCES
      @job.write_output("Generating slugs for Resources")
      @job.write_output("================================")

      Resource.any_repo.each do |r|
        @job.write_output("Generating slug for resource id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # ACCESSIONS
      @job.write_output("Generating slugs for Accessions")
      @job.write_output("================================")

      Accession.any_repo.each do |r|
        @job.write_output("Generating slug for accession id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # DIGITAL OBJECTS
      @job.write_output("Generating slugs for Digital Objects")
      @job.write_output("================================")

      DigitalObject.any_repo.each do |r|
        @job.write_output("Generating slug for digital object id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # CLASSIFICATIONS
      @job.write_output("Generating slugs for Classifications")
      @job.write_output("================================")

      Classification.any_repo.each do |r|
        @job.write_output("Generating slug for classification id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # CLASSIFICATION TERMS
      @job.write_output("Generating slugs for Classification Terms")
      @job.write_output("================================")

      ClassificationTerm.any_repo.each do |r|
        @job.write_output("Generating slug for classification term id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # AGENT - CORPORATE
      @job.write_output("Generating slugs for Agents (Corporate Entities)")
      @job.write_output("================================")

      AgentCorporateEntity.each do |r|
        @job.write_output("Generating slug for agent_corporate_entity id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # AGENT - FAMILY
      @job.write_output("Generating slugs for Agents (Family)")
      @job.write_output("================================")

      AgentFamily.each do |r|
        @job.write_output("Generating slug for agent_family id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # AGENT - Person
      @job.write_output("Generating slugs for Agents (Person)")
      @job.write_output("================================")

      AgentPerson.each do |r|
        @job.write_output("Generating slug for agent_person id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # AGENT - Software
      @job.write_output("Generating slugs for Agents (Software)")
      @job.write_output("================================")

      AgentSoftware.each do |r|
        @job.write_output("Generating slug for agent_software id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # SUBJECT
      @job.write_output("Generating slugs for Subjects")
      @job.write_output("================================")

      Subject.each do |r|
        @job.write_output("Generating slug for subject id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # Archival Object
      @job.write_output("Generating slugs for Archival Objects")
      @job.write_output("================================")

      ArchivalObject.any_repo.each do |r|
        @job.write_output("Generating slug for archival_object id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      # Digital Object Component
      @job.write_output("Generating slugs for Digital Object Components")
      @job.write_output("================================")

      DigitalObjectComponent.any_repo.each do |r|
        @job.write_output("Generating slug for digital object component id: #{r[:id]}")
        r.update(:is_slug_auto => 0, :slug => "")
        r.update(:is_slug_auto => 1)
      end

      self.success!
    rescue
      terminal_error = $!
    end

    if terminal_error
      @job.write_output(terminal_error.message)
      @job.write_output(terminal_error.backtrace)

      raise terminal_error
    end

  end
end
