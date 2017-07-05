class AssessmentAttributeDefinitions

  def self.apply_definitions(repo_id, json)
    definitions = json.definitions

    DB.open do |db|
      # existing definitions get updated
      definitions.each_with_index do |definition, position|
        next unless definition['id']

        db[:assessment_attribute_definition]
          .filter(:repo_id => repo_id, :id => definition['id'])
          .update(definition.merge(:position => position))
      end

      # new definitions are inserted
      definitions.each_with_index do |definition, position|
        next if definition['id']
        db[:assessment_attribute_definition].insert(definition.merge(:repo_id => repo_id, :position => position))
      end
    end
  end

  def self.get(repo_id)
    result = JSONModel(:assessment_attribute_definitions).new

    DB.open do |db|
      db[:assessment_attribute_definition]
        .filter(:repo_id => repo_id)
        .order(:position, :id).each do |definition|

        result.definitions << {
          :id => definition[:id],
          :label => definition[:label],
          :type => definition[:type],
        }
      end
    end

    result
  end

end
