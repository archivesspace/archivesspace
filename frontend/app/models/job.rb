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


  def self.active
    JSONModel::HTTP::get_json(JSONModel(:job).uri_for("active"), "resolve[]" => "repository")
  end


  def self.archived(page)
    JSONModel::HTTP::get_json(JSONModel(:job).uri_for("archived"), :page => page, "resolve[]" => "repository")
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

end
