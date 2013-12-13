require 'fileutils'
require 'securerandom'

require_relative 'user'

class ImportJob < Sequel::Model(:import_job)
  include ASModel
  corresponds_to JSONModel(:job)

  one_to_many :job_files, :class => "ImportJobFile", :key => :job_id
  many_to_one :owner, :key => :owner_id, :class => User

  set_model_scope :repository


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

    target = File.join(AppConfig[:import_job_path], SecureRandom.hex)

    FileUtils.cp(file.path, target)

    target
  end


  def add_file(io)
    storage = self.class.get_file_store
    add_job_file(ImportJobFile.new(:file_path => storage.store(io)))
  end


  def self.sequel_to_jsonmodel(obj, opts = {})
    filenames = ASUtils.json_parse(obj.filenames || "[]")
    json = super
    json.filenames = filenames
    json.owner = obj.owner.username

    json
  end

end
