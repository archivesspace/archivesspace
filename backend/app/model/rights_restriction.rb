class RightsRestriction < Sequel::Model(:rights_restriction)

  include ASModel::ModelScoping
  include ASModel::CRUD

  corresponds_to JSONModel(:rights_restriction)
  set_model_scope :global

  one_to_many :rights_restriction_type


  def linked_record_uri
    self.class.applicable_models.each do |column, model|
      if self[column]
        return model.uri_for(model.my_jsonmodel.record_type, self[column])
      end
    end

    nil
  end


  def self.applicable_models
    @applicable_models ||= calculate_applicable_models
  end


  def self.calculate_applicable_models
    result = {}

    models_supporting_rights_restrictions = ASModel.all_models.select {|model| model.included_modules.include?(RightsRestrictionNotes)}

    models_supporting_rights_restrictions.each do |model|
      join_column = model.association_reflection(:rights_restriction)[:key]

      result[join_column] = model
    end

    result
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['local_access_restriction_type'] = obj.rights_restriction_type.map {|obj| obj.values[:restriction_type]}
      json['linked_records'] = {'ref' => obj.linked_record_uri}
    end

    jsons
  end

end
