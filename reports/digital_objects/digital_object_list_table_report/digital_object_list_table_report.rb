class DigitalObjectListTableReport < AbstractReport

  register_report

  def query
    db[:digital_object].
      left_outer_join(:instance_do_link_rlshp,
           :instance_do_link_rlshp__digital_object_id => :digital_object__id).
      select(Sequel.as(:digital_object__digital_object_id, :identifier),
             Sequel.as(:digital_object__title, :digital_object_title),
             Sequel.as(Sequel.lit('GetEnumValueUF(digital_object.digital_object_type_id)'), :object_type),
             Sequel.as(Sequel.lit('GetDigitalObjectDateExpression(digital_object.id)'), :date_expression),
             Sequel.as(Sequel.lit('GetResourceIdentiferForInstance(instance_do_link_rlshp.instance_id)'), :resource_identifier)).
             filter(:repo_id => @repo_id)
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :resource_identifier) if row[:resource_identifier]
  end

  def page_break
    false
  end

  def identifier_field
    :identifier
  end
end
