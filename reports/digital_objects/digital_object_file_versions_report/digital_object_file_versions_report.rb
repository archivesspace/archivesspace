class DigitalObjectFileVersionsReport < AbstractReport

  register_report

  def template
    'digital_object_file_versions_report.erb'
  end


  def query
    db[:digital_object].
      select(Sequel.as(:id, :digitalObjectId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:digital_object_id, :identifier),
             Sequel.as(:title, :title)).
       filter(:repo_id => @repo_id)
  end

end
