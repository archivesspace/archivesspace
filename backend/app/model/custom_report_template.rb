class CustomReportTemplate < Sequel::Model(:custom_report_template)
  include ASModel
  corresponds_to JSONModel(:custom_report_template)

  set_model_scope :repository

  def validate
    super
    validates_unique(:name, :message => "custom report template name not unique")
  end


  def display_string
    name.to_s
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
    end

    jsons
  end

end
