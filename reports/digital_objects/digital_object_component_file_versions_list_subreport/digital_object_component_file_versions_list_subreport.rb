class DigitalObjectComponentFileVersionsListSubreport < AbstractReport

  def template
    "digital_object_component_file_versions_list_subreport.erb"
  end

  def query
     components = db[:digital_object_component]
                    .select(Sequel.as(:digital_object_component__id, :digitalObjectComponentId),
                            Sequel.as(:digital_object_component__component_id, :digitalObjectComponentIdentifier),
                            Sequel.as(:digital_object_component__title, :digitalObjectComponentTitle))
                    .order(:digital_object_component__position)

    if component_level?
      components.
        filter(:parent_id => @params.fetch(:digitalObjectComponentId))
    else
      components.
        filter(:parent_id => nil).
        and(:root_record_id => @params.fetch(:digitalObjectId))
    end
  end

  def component_level?
    @params.has_key?(:digitalObjectComponentId)
  end

  def show_wrapper_html?(index)
    !component_level? && index == 0
  end

  def file_versions_for(digital_object_component_id)
    db[:file_version]
      .join(:digital_object_component, :id => :digital_object_component_id)
      .filter(:digital_object_component_id => digital_object_component_id)
      .select(Sequel.as(:file_version__id, :file_version_id),
              Sequel.as(:file_version__file_uri, :uri),
              Sequel.as(Sequel.lit("GetEnumValue(file_version.use_statement_id)"), :useStatement))
      .all
  end
end
