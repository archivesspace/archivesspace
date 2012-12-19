require_relative 'indexer_common'

class IndexState

  def initialize
    @state_dir = File.join(AppConfig[:data_directory], "indexer_state")

    FileUtils.mkdir_p(@state_dir)
  end


  def path_for(repository, record_type)
    File.join(@state_dir, "#{repository.id}_#{record_type}")
  end


  def set_last_mtime(repository, record_type, time)
    path = path_for(repository, record_type)

    File.open("#{path}.tmp", "w") do |fh|
      fh.puts(time.to_i)
    end

    File.rename("#{path}.tmp", "#{path}.dat")
  end


  def get_last_mtime(repository, record_type)
    path = path_for(repository, record_type)

    begin
      File.open("#{path}.dat", "r") do |fh|
        fh.readline.to_i
      end
    rescue Errno::ENOENT
      # If we've never run against this repository/type before, just index
      # everything.
      0
    end
  end
end


class PeriodicIndexer < CommonIndexer

  def initialize(state = nil)
    super(AppConfig[:backend_url])
    @state = state || IndexState.new
  end


  def run_index_round
    puts "#{Time.now}: Running index round"

    login

    JSONModel(:repository).all.each do |repository|
      JSONModel.set_repository(repository.id)

      @@record_types.each do |type|
        start = Time.now
        page = 1
        while true
          records = JSONModel(type).all(:page => page,
                                        :modified_since => @state.get_last_mtime(repository, type))

          index_records(records['results'].map {|record|
                          {
                            'record' => record.to_hash,
                            'uri' => record.uri
                          }
                        })

          break if records['last_page'] <= page
          page += 1
        end

        send_commit
        @state.set_last_mtime(repository, type, start)
      end
    end

  end


  def run
    while true
      begin
        run_index_round
      rescue
        reset_session
        puts "#{$!.inspect}"
      end

      sleep AppConfig[:solr_indexing_frequency_seconds].to_i
    end
  end


  def self.get_indexer(state = nil)
    indexer = self.new(state)
  end

end

