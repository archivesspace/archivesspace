require 'fileutils'
require 'tempfile'

class ImportJob < Sequel::Model(:import_job)
  include ASModel
  corresponds_to JSONModel(:job)

  one_to_many :job_files, :class => "ImportJobFile", :key => :job_id


  def self.create_from_json(json, opts = {})
    super(json, opts.merge(:time_submitted => Time.now,
                           :owner_id => opts.fetch(:user).id,
                           :filenames => ASUtils.to_json(json.filenames)))
  end


  def self.get_file_store
    self
  end


  def self.store(file)
    FileUtils.mkdir_p(AppConfig[:import_job_path])

    target = Tempfile.new('import_job', AppConfig[:import_job_path])

    FileUtils.cp(file.path, target.path)

    target.path
  end


  def add_file(io)
    storage = self.class.get_file_store
    add_job_file(ImportJobFile.new(:file_path => storage.store(io)))
  end


  set_model_scope :repository
end
