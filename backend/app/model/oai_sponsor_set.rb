class OAISponsorSet < Sequel::Model(:oai_sponsor_set)
  include ASModel
  include OAISetNames
  corresponds_to JSONModel(:oai_sponsor_set)

  set_model_scope :global

  # Held in one text column as JSON; the schema exposes a real array.
  def sponsor_name_list
    self.sponsor_names.nil? ? [] : ASUtils.json_parse(self.sponsor_names)
  end

  def validate
    super

    validate_set_name(OAIRepositorySet)
  end

  def self.serialize_sponsor_names(json)
    JSON.generate(Array(json['sponsor_names']))
  end

  def self.create_from_json(json, opts = {})
    super(json, opts.merge(:sponsor_names => serialize_sponsor_names(json)))
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    super(json, opts.merge(:sponsor_names => self.class.serialize_sponsor_names(json)), apply_nested_records)
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['sponsor_names'] = obj.sponsor_name_list
    end

    jsons
  end
end
