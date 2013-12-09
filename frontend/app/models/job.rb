class Job

  def initialize(import_type, files_to_import)
    @job = JSONModel(:job).from_hash(:import_type => import_type,
                                     :filenames => files_to_import.keys)

    @files = files_to_import
  end


  def upload
    response = JSONModel::HTTP.post_form(JSONModel(:job).uri_for(nil),
                                         'job' => @job.to_json,
                                         'files[0]' => UploadIO.new(@files.values.first, "text/plain", @files.keys.first),
                                         'files[1]' => UploadIO.new(@files.values.second, "text/plain", @files.keys.second))

    ASUtils.json_parse(response.body)
  end

end
