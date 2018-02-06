# we store the state of uri's index in the indexer_state "directory" in s3
require 'fog/aws'
require 'stringio'
class IndexStateS3

  def initialize(state_dir = 'indexer_state')
    Excon.defaults[:ciphers] = 'DEFAULT'
    @connection = Fog::Storage.new({
      :provider                 => 'AWS',
      :region                   => AppConfig[:index_state_s3][:region],
      :aws_access_key_id        => AppConfig[:index_state_s3][:aws_access_key_id],
      :aws_secret_access_key    => AppConfig[:index_state_s3][:aws_secret_access_key],
    })
    prefix = AppConfig[:index_state_s3][:prefix].call

    @bucket    = @connection.directories.get(AppConfig[:index_state_s3][:bucket])
    @state_dir = "#{prefix}#{state_dir}/"
    create_state_dir
  end

  def create_state_dir
    sd = @bucket.files.get(@state_dir)
    unless sd
      @bucket.files.create(
        key: @state_dir,
        body: nil
      )
    end
  end

  def path_for(repository_id, record_type)
    "#{@state_dir}#{repository_id}_#{record_type}"
  end

  def set_last_mtime(repository_id, record_type, time)
    file = @bucket.files.get(path_for(repository_id, record_type))
    if file
      file.body = StringIO.new("#{time.to_i.to_s}")
      file.save
    else
      @bucket.files.create(
        :key  => path_for(repository_id, record_type),
        :body => StringIO.new("#{time.to_i.to_s}"),
      )
    end
  end

  def get_last_mtime(repository_id, record_type)
    file = @bucket.files.get(path_for(repository_id, record_type))
    if file
      file.body.to_i
    else
      # If we've never run against this repository_id/type before, just index
      # everything.
      0
    end
  end
end
