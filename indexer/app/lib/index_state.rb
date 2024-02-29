# we store the state of uri's index in the indexer_state directory
class IndexState

  def initialize(state_dir = "indexer_state")
    @state_dir = File.join(AppConfig[:data_directory], state_dir)
  end


  def path_for(repository_id, record_type)
    FileUtils.mkdir_p(@state_dir)
    File.join(@state_dir, "#{repository_id}_#{record_type}")
  end


  def set_last_mtime(repository_id, record_type, time)
    path = path_for(repository_id, record_type)

    File.open("#{path}.tmp", "w") do |fh|
      fh.puts(time.to_i)
    end

    # check file exists for multi-instance deployment race condition
    File.rename("#{path}.tmp", "#{path}.dat") if File.exist?("#{path}.tmp")
  end


  def get_last_mtime(repository_id, record_type)
    path = path_for(repository_id, record_type)

    begin
      File.open("#{path}.dat", "r") do |fh|
        fh.readline.to_i
      end
    rescue Errno::ENOENT
      # If we've never run against this repository_id/type before, just index
      # everything.
      0
    end
  end
end
