class Assessment < Sequel::Model(:assessment)

  KEY_TO_TYPE = {
    'ratings' => 'rating',
    'formats' => 'format',
    'conservation_issues' => 'conservation_issue',
  }


  include ASModel
  include AutoGenerator

  corresponds_to JSONModel(:assessment)

  set_model_scope :repository

  define_relationship(:name => :assessment,
                      :json_property => 'records',
                      :contains_references_to_types => proc {[Accession, Resource, ArchivalObject, DigitalObject]})

  define_relationship(:name => :surveyed_by,
                      :json_property => 'surveyed_by',
                      :contains_references_to_types => proc {[AgentPerson]})

  auto_generate :property => :display_string,
                :generator => lambda { |json|
    return "Assessment #{json['id']} display string TODO"
  }

  def self.create_from_json(json, opts = {})
    obj = super
    apply_attributes(obj, json)
    obj
  end


  def update_from_json(json)
    super
    self.class.apply_attributes(self, json)
    self
  end

  def self.apply_attributes(obj, json)
    # Add the appropriate list of attributes
    DB.open do |db|
      db[:assessment_attribute].filter(:assessment_id => obj.id).delete

      KEY_TO_TYPE.each do |key, type|
        Array(json[key]).each do |attribute|
          db[:assessment_attribute].insert(:assessment_id => obj.id,
                                           :value => attribute['value'],
                                           :assessment_attribute_definition_id => attribute['definition_id'])
        end
      end
    end
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

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
            'definition_id' => definition[:id],
          }

          definitions_by_obj[obj.id] ||= {}
          definitions_by_obj[obj.id][definition[:id]] = definition_json

          json[key] << definition_json
        end
      end

      db[:assessment_attribute]
        .filter(:assessment_id => objs.map(&:id))
        .each do |attribute|

        assessment_id = attribute[:assessment_id]
        definition_id = attribute[:assessment_attribute_definition_id]

        definition_json = definitions_by_obj.fetch(assessment_id).fetch(definition_id)

        definition_json['value'] = attribute[:value]
      end

      jsons
    end
  end

  private

  def self.json_key_for_type(target_type)
    KEY_TO_TYPE.each do |key, type|
      if type == target_type
        return key
      end
    end

    raise "Unrecognized type: #{target_type}"
  end

  def self.type_for_json_key(target_key)
    KEY_TO_TYPE.each do |key, type|
      if key == target_key
        return type
      end
    end

    raise "Unrecognized key: #{target_key}"
  end

end
