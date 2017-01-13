class DigitalObjectFileVersionsListSubreport < AbstractReport

  def template
    "digital_object_file_versions_list_subreport.erb"
  end

  def query
    # level = @params.fetch(:level)
    # 
    # if level == :root
    #   db[:file_version]
    #     .join(:digital_object, :id => :digital_object_id)
    #     .select(Sequel.as(:file_version__id, :file_version_id),
    #             Sequel.as(:file_version__file_uri, :uri),
    #             Sequel.as(:digital_object_component__component_id, :digitalObjectComponentIdentifier),
    #             Sequel.as(:digital_object_component__title, :digitalObjectComponentTitle),
    #             Sequel.as(Sequel.lit("GetEnumValue(file_version.use_statement_id)"), :useStatement))
    #     .order(:digital_object_component__position)
    # elsif level == :top
    # elsif level == :child
    # else
    #   raise "Level not recongnised: #{level}" 
    # end
    # 
    # file_versions = db[:file_version]
    #                   .join(:digital_object_component, :id => :digital_object_component_id)
    #                   .select(Sequel.as(:file_version__id, :file_version_id),
    #                           Sequel.as(:file_version__digital_object_id, :file_version_digital_object_id),
    #                           Sequel.as(:file_version__file_uri, :uri),
    #                           Sequel.as(:digital_object_component__component_id, :digitalObjectComponentIdentifier),
    #                           Sequel.as(:digital_object_component__title, :digitalObjectComponentTitle),
    #                           Sequel.as(Sequel.lit("GetEnumValue(file_version.use_statement_id)"), :useStatement))
    #                   .order(:digital_object_component__position)
    # 
    # if @params[:top_level]
    #   file_versions.
    #     filter(:parent_id => nil).
    #     and(:root_record_id => @params.fetch(:digitalObjectId))
    # else
    #   file_versions.
    #     filter(:parent_id => @params.fetch(:digitalObjectComponentId))
    # end

    db[:file_version]
      .join(:digital_object, :id => :digital_object_id)
      .filter(:digital_object__id => @params.fetch(:digitalObjectId))
      .select(Sequel.as(:file_version__id, :file_version_id),
              Sequel.as(:file_version__file_uri, :uri),
              Sequel.as(Sequel.lit("GetEnumValue(file_version.use_statement_id)"), :useStatement))
  end

end
