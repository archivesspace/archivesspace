class RdeTemplate < Sequel::Model(:rde_template)
  include ASModel
  corresponds_to JSONModel(:rde_template)

  set_model_scope :repository


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['order'] = ASUtils.json_parse(obj.order)
      json['visible'] = ASUtils.json_parse(obj.visible)
      json['defaults'] = ASUtils.json_parse(obj.defaults)
    end

    jsons
  end

  def self.create_from_json(json, opts = {})
    super(json, opts.merge('order' => JSON(json.order || []),
                           'visible' => JSON(json.visible || []),
                           'defaults' => JSON(json.defaults || {})
                           ))
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    super(json, opts.merge('order' => JSON(json.order || []),
                           'visible' => JSON(json.visible || []),
                           'defaults' => JSON(json.defaults || {})
                           ))
  end


end
