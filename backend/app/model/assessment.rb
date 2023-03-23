class Assessment < Sequel::Model(:assessment)

  KEY_TO_TYPE = {
    'ratings' => 'rating',
    'formats' => 'format',
    'conservation_issues' => 'conservation_issue',
  }


  include ASModel

  corresponds_to JSONModel(:assessment)

  include ExternalDocuments

  set_model_scope :repository

  define_relationship(:name => :assessment,
                      :json_property => 'records',
                      :contains_references_to_types => proc {[Accession, Resource, ArchivalObject, DigitalObject]})

  define_relationship(:name => :surveyed_by,
                      :json_property => 'surveyed_by',
                      :contains_references_to_types => proc {[AgentPerson]})

  define_relationship(:name => :assessment_reviewer,
                      :json_property => 'reviewer',
                      :contains_references_to_types => proc {[AgentPerson]})

  def self.create_from_json(json, opts = {})
    prepare_monetary_value_for_save(json, opts)
    obj = super
    apply_attributes(obj, json)
    obj
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.prepare_monetary_value_for_save(json, opts)
    super
    self.class.apply_attributes(self, json)
    self
  end

  # Represents a repository-scoped attribute that we're going to try to find a
  # match for in the target repository when transferring or cloning an
  # assessment.
  TransferRepoAttribute = Struct.new(:definition_id, :label, :type, :value, :note)

  def transfer_to_repository(repository, transfer_group = [])
    # When we transfer an assessment to another repository, it might contain
    # references to attribute definitions that belong to its originating
    # repository.
    #
    # Rather than outright breaking those links, we attempt to find a
    # corresponding attribute in the target repository (based on attribute
    # label).  So the assumption here is that two attributes with the same label
    # are equivalent.
    DB.open do |db|
      repo_attribute_links = db[:assessment_attribute_definition]
                               .left_join(:assessment_attribute, :assessment_attribute_definition_id => :assessment_attribute_definition__id)
                               .left_join(:assessment_attribute_note, :assessment_attribute_definition_id => :assessment_attribute_definition__id)
                               .filter(:assessment_attribute_definition__repo_id => self.class.active_repository)
                               .where(Sequel.|({:assessment_attribute__assessment_id => self.id},
                                               {:assessment_attribute_note__assessment_id => self.id}))
                               .select(:assessment_attribute_definition__id,
                                       :assessment_attribute_definition__label,
                                       :assessment_attribute_definition__type,
                                       :assessment_attribute__value,
                                       :assessment_attribute_note__note)
                               .map {|row| TransferRepoAttribute.new(row[:id], row[:label], row[:type], row[:value], row[:note])}

      # Do the transfer
      super

      # Make sure we observe the updated repo_id
      self.refresh

      unless repo_attribute_links.empty?
        # Unlink the repository-scoped attributes and notes that are no longer valid
        db[:assessment_attribute]
          .filter(:assessment_id => self.id,
                  :assessment_attribute_definition_id => repo_attribute_links.map(&:definition_id))
          .delete

        db[:assessment_attribute_note]
          .filter(:assessment_id => self.id,
                  :assessment_attribute_definition_id => repo_attribute_links.map(&:definition_id))
          .delete

        # Search for replacements based on label and link them up
        self.class.apply_matching_repo_attributes_for_transferred_assessment(self, repo_attribute_links)
      end
    end
  end

  # Like `create_from_json` but runs in the context where we have `json` taken
  # from repo A and we want to create an equivalent record in the current
  # repository.
  #
  # This happens in the context of repository transfers where some (but not all)
  # of the records linked to an assessment are being moved to a different
  # repository.  The situation is similar to `transfer_to_repository` (see
  # above), but instead of transferring the assessment we'll create a new
  # version in the target repository.
  #
  def self.clone_from_json(json, opts = {})
    repo_attribute_links = []

    repo_attribute_links += extract_transfer_repo_attributes(json.ratings, 'rating')
    repo_attribute_links += extract_transfer_repo_attributes(json.formats, 'format')
    repo_attribute_links += extract_transfer_repo_attributes(json.conservation_issues, 'conservation_issue')

    # Create as normal, which will drop any attributes that belonged to the old repository
    cloned_assessment = create_from_json(json, opts)

    # Finally, create as many of them as we can by matching against attributes
    # in the new repository.
    apply_matching_repo_attributes_for_transferred_assessment(cloned_assessment, repo_attribute_links)

    cloned_assessment
  end

  def self.apply_attributes(obj, json)
    # Add the appropriate list of attributes
    DB.open do |db|
      db[:assessment_attribute].filter(:assessment_id => obj.id).delete
      db[:assessment_attribute_note].filter(:assessment_id => obj.id).delete

      valid_attribute_ids = db[:assessment_attribute_definition]
                              .filter(:repo_id => [Repository.global_repo_id, active_repository])
                              .select(:id)
                              .map {|row| row[:id]}
      KEY_TO_TYPE.each do |key, type|
        Array(json[key]).each do |attribute|
          next unless valid_attribute_ids.include?(attribute['definition_id'])

          if attribute['value']
            db[:assessment_attribute].insert(:assessment_id => obj.id,
                                             :value => attribute['value'],
                                             :assessment_attribute_definition_id => attribute['definition_id'])
          end

          if attribute['note']
            db[:assessment_attribute_note].insert(:assessment_id => obj.id,
                                                  :note => attribute['note'],
                                                  :assessment_attribute_definition_id => attribute['definition_id'])
          end
        end
      end

      # Calculate the derived "Research Value" rating (the sum of Interest and Documentation Quality)
      research_value_id = db[:assessment_attribute_definition].filter(:label => 'Research Value').get(:id)
      values = db[:assessment_attribute]
        .join(:assessment_attribute_definition, :id => :assessment_attribute__assessment_attribute_definition_id)
        .filter(:assessment_attribute_definition__label => ['Interest', 'Documentation Quality'],
                :assessment_attribute__assessment_id => obj.id)
        .select(:assessment_attribute__value)
        .map {|row| row[:value] ? (Integer(row[:value]) rescue nil) : nil}

      research_value = values.compact.reduce {|sum, n| sum + n}

      if research_value
        db[:assessment_attribute].insert(:assessment_id => obj.id,
                                         :value => research_value.to_s,
                                         :assessment_attribute_definition_id => research_value_id)
      end
    end
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    prepare_monetary_value_for_jsonmodel(objs, jsons)

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.id.to_s
      json['collections'] = obj.linked_collection_uris.map {|uri| {
        'ref' => uri
      }}
    end

    definitions_by_obj = {}

    # each assessment has some attributes that link to a definition
    DB.open do |db|
      db[:assessment_attribute_definition]
        .filter(:repo_id => [Repository.global_repo_id, active_repository])
        .each do |definition|
        jsons.zip(objs).each do |json, obj|
          KEY_TO_TYPE.each do |key, type|
            json[key] ||= []
          end

          key = json_key_for_type(definition[:type])
          definition_json = {
            'global' => definition[:repo_id] == Repository.global_repo_id,
            'label' => definition[:label],
            'value' => nil,
            'note' => nil,
            'readonly' => (definition[:readonly] == 1),
            'definition_id' => definition[:id],
          }

          definitions_by_obj[obj.id] ||= {}
          definitions_by_obj[obj.id][definition[:id]] = definition_json

          json[key] << definition_json
        end
      end

      # Load our attribute values
      db[:assessment_attribute]
        .filter(:assessment_id => objs.map(&:id))
        .each do |attribute|

        assessment_id = attribute[:assessment_id]
        definition_id = attribute[:assessment_attribute_definition_id]

        definition_json = definitions_by_obj.fetch(assessment_id).fetch(definition_id)

        definition_json['value'] = attribute[:value]
      end

      # Load our attribute notes
      db[:assessment_attribute_note]
        .filter(:assessment_id => objs.map(&:id))
        .each do |attribute|

        assessment_id = attribute[:assessment_id]
        definition_id = attribute[:assessment_attribute_definition_id]

        definition_json = definitions_by_obj.fetch(assessment_id).fetch(definition_id)

        definition_json['note'] = attribute[:note]
      end

      jsons
    end
  end


  def linked_collection_uris
    uris = self.class.find_relationship(:assessment).who_participates_with(self).map do |record|
      if record.is_a? Resource
        JSONModel(:resource).uri_for(record.id, :repo_id => record.repo_id)
      elsif record.is_a? ArchivalObject
        JSONModel(:resource).uri_for(record.root_record_id, :repo_id => record.repo_id)
      end
    end

    uris.compact.uniq
  end


  private

  def self.apply_matching_repo_attributes_for_transferred_assessment(cloned_assessment, repo_attribute_links)
    DB.open do |db|
      repo_attribute_links.each do |link|
        replacement = db[:assessment_attribute_definition]
                        .filter(:repo_id => cloned_assessment.repo_id,
                                :label => link.label,
                                :type => link.type)
                        .first

        if replacement
          if link.value
            db[:assessment_attribute].insert(:assessment_id => cloned_assessment.id,
                                             :assessment_attribute_definition_id => replacement[:id],
                                             :value => link.value)
          end

          if link.note
            db[:assessment_attribute_note].insert(:assessment_id => cloned_assessment.id,
                                                  :assessment_attribute_definition_id => replacement[:id],
                                                  :note => link.note)
          end
        end
      end
    end
  end


  def self.extract_transfer_repo_attributes(attribute_list, attribute_type)
    attribute_list.map {|attribute|
      unless attribute['global']
        TransferRepoAttribute.new(attribute['definition_id'],
                                  attribute['label'],
                                  attribute_type,
                                  attribute['value'],
                                  attribute['note'])
      end
    }.compact
  end

  def self.prepare_monetary_value_for_save(json, opts)
    if json['monetary_value']
      mv = BigDecimal(json['monetary_value']) rescue ''
      opts['monetary_value'] = mv
    end
  end

  def self.prepare_monetary_value_for_jsonmodel(objs, jsons)
    jsons.zip(objs).each do |json, obj|
      # These columns come out of the DB as BigDecimal objects.  Format them as
      # NNN.DD.
      if obj[:monetary_value]
        value = obj[:monetary_value].to_s('F')

        # If the value is 500.0, just render as 500
        value = value.gsub(/\.0$/, '')

        # If the value is 500.4, show 500.40
        if value =~ /\.[0-9]$/
          value += '0'
        end

        json[:monetary_value] = value
      end
    end

    jsons
  end

  def self.json_key_for_type(target_type)
    KEY_TO_TYPE.each do |key, type|
      if type == target_type
        return key
      end
    end

    raise "Unrecognized type: #{target_type}"
  end


  def self.handle_delete(ids_to_delete)
    DB.open do |db|
      db[:assessment_attribute_note].filter(:assessment_id => ids_to_delete).delete
      db[:assessment_attribute].filter(:assessment_id => ids_to_delete).delete
    end

    super
  end
end
