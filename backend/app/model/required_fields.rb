class RequiredFields < Sequel::Model(:required_fields)
  include ASModel
  corresponds_to JSONModel(:required_fields)

  set_model_scope :repository

  def self.create_or_update(json, repo_id, record_type)
    id = "#{repo_id}_#{record_type}"

    if self[id]
      self[id].update_from_json(json)
    else
      self.create_from_json(json, {:id => "#{repo_id}_#{record_type}"})
    end

    self[id]
  end


  def self.to_jsonmodel(obj, opts = {})
    if obj.is_a? String
      obj = RequiredFields[obj]
      raise NotFoundException.new("#{self} not found") unless obj
    end

    self.sequel_to_jsonmodel([obj], opts)[0]

  end


  def self.sequel_to_jsonmodel(objs, opts = {})

    jsons = objs.map {|obj|
      json = JSONModel(:required_fields).new(ASUtils.json_parse(obj[:blob]))
      json.uri = obj.uri
      json.lock_version = obj.lock_version
      json
    }

    jsons
  end


  def self.create_from_json(json, opts = {})
    super(json, opts.merge('blob' => json.to_json))
  end


  def update_from_json(json, opts = {}, apply_nested_records = false)
    json['lock_version'] ||= 0
    super(json, opts.merge('blob' => json.to_json))
  end


  def uri
    "/repositories/#{self.repo_id}/required_fields/#{self.record_type}"
  end

end


RequiredFields.unrestrict_primary_key
