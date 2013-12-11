class Job

  def initialize(import_type, files_to_import)
    @job = JSONModel(:job).from_hash(:import_type => import_type,
                                     :filenames => files_to_import.keys)

    @files = files_to_import
  end


  def upload
    upload_files = @files.each_with_index.map {|file, i|
      (original_filename, stream) = file
      ["files[#{i}]", UploadIO.new(stream, "text/plain", original_filename)]
    }

    response = JSONModel::HTTP.post_form(JSONModel(:job).uri_for(nil),
                                         Hash[upload_files].merge('job' => @job.to_json),
                                         :multipart_form_data)

    ASUtils.json_parse(response.body)
  end

end
