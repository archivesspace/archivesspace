class Job

  def initialize(job_type, job_data, files_to_import, job_params = {})

    if job_type == 'import_job'
      job_data[:filenames] = files_to_import.keys
    end

    @job = JSONModel(:job).from_hash(:job_type => job_type,
                                     :job => job_data,
                                     :job_params =>  ASUtils.to_json(job_params) )

    @files = files_to_import
  end


  def upload
    unless @files.empty?

      upload_files = @files.each_with_index.map {|file, i|
        (original_filename, stream) = file
        ["files[#{i}]", UploadIO.new(stream, "text/plain", original_filename)]
      }

      response = JSONModel::HTTP.post_form("#{JSONModel(:job).uri_for(nil)}_with_files",
                                           Hash[upload_files].merge('job' => @job.to_json),
                                           :multipart_form_data)

      ASUtils.json_parse(response.body)

    else

      @job.save

      {:uri => @job.uri}
    end

  end


  def self.active
    JSONModel::HTTP::get_json(JSONModel(:job).uri_for("active"), "resolve[]" => "repository") || {'results' => []}
  end


  def self.archived(page)
    JSONModel::HTTP::get_json(JSONModel(:job).uri_for("archived"), :page => page, "resolve[]" => "repository") || {'results' => []}
  end


  def self.log(id, offset = 0, &block)
    JSONModel::HTTP::stream("#{JSONModel(:job).uri_for(id)}/log", {:offset => offset}, &block)
  end


  def self.records(id, page)
    JSONModel::HTTP::get_json("#{JSONModel(:job).uri_for(id)}/records", :page => page, "resolve[]" => "record")
  end


  def self.cancel(id)
    response = JSONModel::HTTP.post_form("#{JSONModel(:job).uri_for(id)}/cancel")

    ASUtils.json_parse(response.body)
  end


  def self.available_types
    JSONModel::HTTP.get_json(JSONModel(:job).uri_for("types"))
  end


  def self.available_import_types
    JSONModel::HTTP.get_json(JSONModel(:job).uri_for("import_types"))
  end
end
