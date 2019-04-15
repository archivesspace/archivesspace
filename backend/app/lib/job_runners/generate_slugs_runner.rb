class GenerateSlugsRunner < JobRunner

  register_for_job_type('generate_slugs_job',
                        {:create_permissions => :manage_repository,
                         :cancel_permissions => :manage_repository,
                         :allow_reregister => true})

   def generate_slug_for(thing)
     json_like_hash = thing.values
     AppConfig[:auto_generate_slugs_with_id] ? 
       SlugHelpers.id_based_slug_for(json_like_hash, thing.class) : 
       SlugHelpers.name_based_slug_for(json_like_hash, thing.class)
   end
  
  def run
    begin
      # REPOSITORIES
      @job.write_output("Generating slugs for Repositories")
      @job.write_output("================================")

      Repository.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for repository id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for repository id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # RESOURCES
      @job.write_output("Generating slugs for Resources")
      @job.write_output("================================")

      Resource.any_repo.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for classification_term id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for classification_term id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # ACCESSIONS
      @job.write_output("Generating slugs for Accessions")
      @job.write_output("================================")

      Accession.any_repo.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for accession id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for accession id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # DIGITAL OBJECTS
      @job.write_output("Generating slugs for Digital Objects")
      @job.write_output("================================")

      DigitalObject.any_repo.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for digital_object id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for digital_object id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # CLASSIFICATIONS
      @job.write_output("Generating slugs for Classifications")
      @job.write_output("================================")

      Classification.any_repo.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for classification id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for classification id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # CLASSIFICATION TERMS
      @job.write_output("Generating slugs for Classification Terms")
      @job.write_output("================================")

      ClassificationTerm.any_repo.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for classification_term id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for classification_term id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # AGENT - CORPORATE
      @job.write_output("Generating slugs for Agents (Corporate Entities)")
      @job.write_output("================================")

      AgentCorporateEntity.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for agent_corporate_entity id: #{r[:id]}")
          agent_name = NameCorporateEntity.find(:agent_corporate_entity_id => r.id)
          slug = generate_slug_for(agent_name)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for agent_corporate_entity id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # AGENT - FAMILY
      @job.write_output("Generating slugs for Agents (Family)")
      @job.write_output("================================")

      AgentFamily.each do |r|
        r[:slug] = "" if r[:slug].nil?
       next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for agent_family id: #{r[:id]}")
          agent_name = NameFamily.find(:agent_family_id => r.id)
          slug = generate_slug_for(agent_name)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for agent_family id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # AGENT - Person
      @job.write_output("Generating slugs for Agents (Person)")
      @job.write_output("================================")

      AgentPerson.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for agent_person id: #{r[:id]}")
          agent_name = NamePerson.find(:agent_person_id => r.id)
          slug = generate_slug_for(agent_name)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for agent_person id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # AGENT - Software
      @job.write_output("Generating slugs for Agents (Software)")
      @job.write_output("================================")

      AgentSoftware.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for agent_software id: #{r[:id]}")
          agent_name = NameSoftware.find(:agent_software_id => r.id)
          slug = generate_slug_for(agent_name)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for agent_software id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # SUBJECT
      @job.write_output("Generating slugs for Subjects")
      @job.write_output("================================")

      Subject.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for subject id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for subject id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # Archival Object
      @job.write_output("Generating slugs for Archival Objects")
      @job.write_output("================================")

      ArchivalObject.any_repo.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for archival_object id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for archival_object id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
      end

      # Digital Object Component
      @job.write_output("Generating slugs for Digital Object Components")
      @job.write_output("================================")

      DigitalObjectComponent.any_repo.each do |r|
        r[:slug] = "" if r[:slug].nil?

        next if !r[:slug].empty? && r[:is_slug_auto] == 0
        begin
          @job.write_output("Generating slug for digital_object_component id: #{r[:id]}")
          slug = generate_slug_for(r)

          if slug && !slug.empty?
            @job.write_output(" -> Slug for digital_object_component id: #{r[:id]} => #{slug}")
            r.update(:is_slug_auto => 1, :slug => slug)
          else
            @job.write_output(" -> Generated empty slug for: #{r[:id]}")
          end

        rescue => e
          @job.write_output(" -> Error generating slug for id: #{r[:id]} => #{e.message}")
        end
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
