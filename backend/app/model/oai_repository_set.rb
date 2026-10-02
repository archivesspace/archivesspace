class OAIRepositorySet < Sequel::Model(:oai_repository_set)
  include ASModel
  include OAISetNames
  corresponds_to JSONModel(:oai_repository_set)

  set_model_scope :global

  # Held in one text column as JSON; the schema exposes a real array.
  def repo_code_list
    self.repo_codes.nil? ? [] : ASUtils.json_parse(self.repo_codes)
  end

  def validate
    super

    validate_set_name(OAISponsorSet)
  end

  def self.serialize_repo_codes(json)
    JSON.generate(Array(json['repo_codes']))
  end

  def self.create_from_json(json, opts = {})
    super(json, opts.merge(:repo_codes => serialize_repo_codes(json)))
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    super(json, opts.merge(:repo_codes => self.class.serialize_repo_codes(json)), apply_nested_records)
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['repo_codes'] = obj.repo_code_list
    end

    jsons
  end
end
