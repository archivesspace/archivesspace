require 'fileutils'
require 'securerandom'

require_relative 'user'

class ImportJob < Sequel::Model(:import_job)
  include ASModel
  corresponds_to JSONModel(:job)

  one_to_many :job_files, :class => "ImportJobFile", :key => :job_id
  many_to_one :owner, :key => :owner_id, :class => User

  set_model_scope :repository


  class JobFileStore

    def initialize(name)
      @job_path = File.join(AppConfig[:import_job_path], name)
      FileUtils.mkdir_p(@job_path)
      @output = File.open(File.join(@job_path, "output.log"), "w")
    end


    def store(file)
      target = File.join(@job_path, SecureRandom.hex)

      FileUtils.cp(file.path, target)

      target
    end


    def write_output(s)
      @output.puts(s)
    end


    def close_output
      if @output
        @output.close
        @output = nil
      end
    end


    def unlink(path)
      File.unlink(path)
    end

  end


  def self.create_from_json(json, opts = {})
    super(json, opts.merge(:time_submitted => Time.now,
                           :owner_id => opts.fetch(:user).id,
                           :filenames => ASUtils.to_json(json.filenames)))
  end


  def file_store
    @file_store ||= JobFileStore.new("import_job_#{id}")
  end


  def add_file(io)
    add_job_file(ImportJobFile.new(:file_path => file_store.store(io)))
  end


  def write_output(s)
    file_store.write_output(s)
  end


  def finish(status)
    file_store.close_output

    self.reload
    self.status = "#{status}"
    self.time_finished = Time.now
    self.save
  end


  def self.sequel_to_jsonmodel(obj, opts = {})
    filenames = ASUtils.json_parse(obj.filenames || "[]")
    json = super
    json.filenames = filenames
    json.owner = obj.owner.username

    json
  end


  def remove_files
    job_files.each do |file|
      file_store.unlink(file.file_path)
    end
  end

end
