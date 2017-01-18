class DigitalObjectFileVersionsReport < AbstractReport

  register_report({
                    :uri_suffix => "digital_object_file_versions_report",
                    :description => "Displays any file versions associated with the selected digital objects.",
                  })

  def title
    "File version list"
  end

  def template
    'digital_object_file_versions_report.erb'
  end


  def query
    db[:digital_object].
      select(Sequel.as(:id, :digitalObjectId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:digital_object_id, :identifier),
             Sequel.as(:title, :title))
  end

  # Number of Records
  def total_count
    @total_count ||= self.query.count
  end
end
