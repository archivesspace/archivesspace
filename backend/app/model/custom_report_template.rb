class CustomReportTemplate < Sequel::Model(:custom_report_template)
  include ASModel
  corresponds_to JSONModel(:custom_report_template)

  set_model_scope :repository

  def validate
    super
    validates_unique(:name, :message => "custom report template name not unique")
    data_validation
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

  private

  def data_validation
    data_hash = ASUtils.json_parse(data)
    unless has_included_fields(data_hash)
      errors.add(:field, 'custom report must include field or subreport')
    end

    data_hash['fields'].each do |field_name, info|
      if !missing(info['range_start']) && missing(info['range_end'])
        errors.add(:"data_#{data_hash['custom_record_type']}_fields_#{field_name}_range_end", 'missing end filter date')
      elsif missing(info['range_start']) && !missing(info['range_end'])
        errors.add(:"data_#{data_hash['custom_record_type']}_fields_#{field_name}_range_start", 'missing start filter date')
      end
    end
  end

  def has_included_fields(data)
    [data['fields'], data['subreports']].each do |field_list|
      next unless field_list
      field_list.each do |k, v|
        return true if v['include']
      end
    end
    false
  end

  def missing(var)
    var.nil? || var.empty?
  end

end
