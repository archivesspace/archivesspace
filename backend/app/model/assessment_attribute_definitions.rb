class AssessmentAttributeDefinitions

  extend JSONModel

  def self.apply_definitions(repo_id, json)
    # Global definitions are immutable, so drop them out here.
    definitions = json.definitions.reject {|d| d['global']}
    definitions.each do |d| d.delete('global'); end

    DB.open do |db|
      # Deleted things are deleted!  That is, IDs that aren't in our new list
      begin
        db[:assessment_attribute_definition]
          .filter(:repo_id => repo_id)
          .where { Sequel.~(:id => definitions.map {|d| d['id']}.compact) }
          .delete
      rescue Sequel::ForeignKeyConstraintViolation
          raise ConflictException.new("RECORD_IN_USE")
      end


      # Don't allow a label to be set if it would conflict with a label used by one of the global attributes
      definitions.each do |d|
        conflicting_labels = db[:assessment_attribute_definition]
                               .filter(:repo_id => 1, :type => d['type'], :label => d['label'])
                               .select(:label)
                               .all

        unless conflicting_labels.empty?
          raise ConflictException.new(conflicting_labels.map {|row| row[:label]})
        end

        conflicting_repo_labels = db[:assessment_attribute_definition]
                                    .filter(:repo_id => repo_id,
                                            :type => d['type'],
                                            :label => d['label'])
                                    .where { Sequel.~(:id => d['id']) }
                                    .select(:label)
                                    .all

        unless conflicting_repo_labels.empty?
          raise ConflictException.new(conflicting_repo_labels.map {|row| row[:label]})
        end
      end

      # Existing definitions get updated
      definitions.each_with_index do |definition, position|
        next unless definition['id']

        db[:assessment_attribute_definition]
          .filter(:repo_id => repo_id, :id => definition['id'])
          .update(definition.merge('position' => position,
                                   'readonly' => (definition['readonly'] ? 1 : 0)))
      end

      # New definitions are inserted
      seen_labels = {}

      definitions.each_with_index do |definition, position|
        next if definition['id'] || seen_labels[definition['label']]

        seen_labels[definition['label']] = true
        db[:assessment_attribute_definition].insert(definition.merge('repo_id' => repo_id,
                                                                     'position' => position,
                                                                     'readonly' => (definition['readonly'] ? 1 : 0)))
      end
    end
  end

  def self.get(repo_id)
    result = JSONModel(:assessment_attribute_definitions).new

    logical_position_by_repo_and_type = {}

    DB.open do |db|
      db[:assessment_attribute_definition]
        .filter(:repo_id => [repo_id, Repository.global_repo_id])
        .order(:repo_id, :position, :id).each do |definition|

        logical_position_by_repo_and_type[definition[:repo_id]] ||= {}
        logical_position_by_repo_and_type[definition[:repo_id]][definition[:type]] ||= 0

        result.definitions << {
          :id => definition[:id],
          :label => definition[:label],
          :type => definition[:type],
          :global => (definition[:repo_id] == Repository.global_repo_id),
          :readonly => (definition[:readonly] == 1),
          :position => logical_position_by_repo_and_type[definition[:repo_id]][definition[:type]],
        }

        logical_position_by_repo_and_type[definition[:repo_id]][definition[:type]] += 1
      end
    end

    result
  end

end
