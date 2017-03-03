require 'fileutils'
require 'securerandom'
require 'stringio'

require_relative 'user'

require_relative 'job_created_record'
require_relative 'job_modified_record'
require_relative 'job_files'


class Job < Sequel::Model(:job)
  include ASModel
  corresponds_to JSONModel(:job)

  many_to_one :owner, :key => :owner_id, :class => User
  one_to_many :job_files, :class => JobFile, :key => :job_id
  one_to_many :created_records, :class => JobCreatedRecord, :key => :job_id
  one_to_many :modified_records, :class => JobModifiedRecord, :key => :job_id


  set_model_scope :repository


  class JobFileStore

    def initialize(name)
      @job_path = File.join(AppConfig[:job_file_path], name)
      FileUtils.mkdir_p(@job_path)
      @output_path = File.join(@job_path, "output.log")
    end


    def store(file)
      target = File.join(@job_path, SecureRandom.hex)

      FileUtils.cp(file.path, target)

      target
    end


    def write_output(s)
      @output ||= File.open(@output_path, "a")
      @output.puts(s)
      @output.flush
    end


    def get_output_stream(offset = 0)
      @output.flush if @output

      f = File.open(@output_path, "r")
      f.seek(offset, IO::SEEK_SET)

      [f, [(f.stat.size - offset), 0].max]
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
    if json.job_params == "null" 
      json.job_params = ""
    end
    
    super(json, opts.merge(:time_submitted => Time.now,
                           :owner_id => opts.fetch(:user).id,
                           :job_blob => ASUtils.to_json(json.job),
                           :job_params => ASUtils.to_json(json.job_params) 
                          ))
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super
    jsons.zip(objs).each do |json, obj|
      json.job = JSONModel(obj.type.intern).from_hash(obj.job)
      json.owner = obj.owner.username
      json.queue_position = obj.queue_position if obj.status === "queued"
    end

    jsons
  end


  def self.queued_jobs
    self.any_repo.filter(:status => 'queued').order(:time_submitted)
  end


  def self.running_jobs
    self.any_repo.filter(:status => 'running').order(:time_submitted)
  end


  def self.running_jobs_untouched_since(time)
    self.any_repo.filter(:status => "running").where { system_mtime < time } 
  end


  def self.any_running?(type)
    !self.any_repo.filter(:status => 'running')
         .where(Sequel.like(:job_blob, '%"jsonmodel_type":"' + type + '"%')).empty?
  end


  def type
    job['jsonmodel_type']
  end


  def job
    @job ||= ASUtils.json_parse(job_blob)
  end


  def file_store
    @file_store ||= JobFileStore.new("#{type}_#{id}")
  end


  def add_file(io)
    add_job_file(JobFile.new(:file_path => file_store.store(io)))
  end


  def write_output(s)
    file_store.write_output(s)
  end


  def get_output_stream(offset = 0)
    begin
      file_store.get_output_stream(offset)
    rescue
      [StringIO.new(""), 0]
    end
  end


  def record_created_uris(uris)
    uris.each do |uri|
      add_created_record(:record_uri => uri)
    end
  end


  def record_modified_uris(uris)
    uris.each do |uri|
      add_modified_record(:record_uri => uri)
    end
  end


  def queue_position
    DB.open do |db|
      job_id = self.id
      db[:job].where { id < job_id }.where(:status => "queued").count
    end
  end


  def start!
    self.status = 'running'
    self.time_started = Time.now
    self.save
  end


  def finish!(status)
    file_store.close_output

    self.reload
    self.status = [:canceled, :failed].include?(status) ? status.to_s : 'completed'
    self.time_finished = Time.now
    self.save
  end


  def success?
    self.reload
    self.status == 'completed'
  end


  def cancel!
    if ["queued", "running"].include? self.status
      self.status = "canceled"
      self.save
    end
  end


  def update_mtime
    Job.update_mtime_for_ids([self.id])
  end

end
