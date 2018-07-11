class DigitalObjectFileVersionsListSubreport < AbstractReport

  def template
    "digital_object_file_versions_list_subreport.erb"
  end

  def query
    db[:file_version]
      .join(:digital_object, :id => :digital_object_id)
      .filter(:digital_object__id => @params.fetch(:digitalObjectId))
      .select(Sequel.as(:file_version__id, :file_version_id),
              Sequel.as(:file_version__file_uri, :uri),
              Sequel.as(Sequel.lit("GetEnumValue(file_version.use_statement_id)"), :useStatement))
  end

end
