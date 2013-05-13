require_relative 'indexer_common'
require 'time'

class IndexState

  def initialize
    @state_dir = File.join(AppConfig[:data_directory], "indexer_state")

    FileUtils.mkdir_p(@state_dir)
  end


  def path_for(repository_id, record_type)
    File.join(@state_dir, "#{repository_id}_#{record_type}")
  end


  def set_last_mtime(repository_id, record_type, time)
    path = path_for(repository_id, record_type)

    File.open("#{path}.tmp", "w") do |fh|
      fh.puts(time.to_i)
    end

    File.rename("#{path}.tmp", "#{path}.dat")
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


class PeriodicIndexer < CommonIndexer

  # A small window to account for the fact that transactions might be committed
  # after the periodic indexer has checked for updates, but with timestamps from
  # prior to the check.
  WINDOW_SECONDS = 30

  PAGE_SIZE = 100

  def initialize(state = nil)
    super(AppConfig[:backend_url])
    @state = state || IndexState.new
  end


  def handle_deletes
    start = Time.now
    last_mtime = @state.get_last_mtime('_deletes', 'deletes')
    did_something = false

    page = 1
    while true
      deletes = JSONModel::HTTP.get_json("/delete-feed", :modified_since => [last_mtime - WINDOW_SECONDS, 0].max, :page => page, :page_size => PAGE_SIZE)

      if !deletes['results'].empty?
        did_something = true
      end

      delete_records(deletes['results'])

      break if deletes['last_page'] <= page

      page += 1
    end

    send_commit if did_something

    @state.set_last_mtime('_deletes', 'deletes', start)
  end


  def run_index_round
    puts "#{Time.now}: Running index round"

    login

    # Index any repositories that were changed
    start = Time.now
    repositories = JSONModel(:repository).all

    modified_since = [@state.get_last_mtime('repositories', 'repositories') - WINDOW_SECONDS, 0].max
    updated_repositories = repositories.reject {|repository| Time.parse(repository['last_modified']).to_i < modified_since}.
                                        map {|repository| {
        'record' => repository.to_hash(:trusted),
        'uri' => repository.uri
      }
    }

    if !updated_repositories.empty?
      index_records(updated_repositories)
      send_commit
    end

    @state.set_last_mtime('repositories', 'repositories', start)


    # And any records in any repositories
    repositories.each do |repository|
      JSONModel.set_repository(repository.id)

      did_something = false
      checkpoints = []

      @@record_types.each do |type|
        start = Time.now

        modified_since = [@state.get_last_mtime(repository.id, type) - WINDOW_SECONDS, 0].max
        id_set = JSONModel::HTTP.get_json(JSONModel(type).uri_for, :all_ids => true, :modified_since => modified_since)

        id_set.each_slice(PAGE_SIZE) do |id_subset|

          records = JSONModel(type).all(:id_set => id_subset.join(","),
                                        'resolve[]' => @@resolved_attributes)

          if !records.empty?
            did_something = true
            index_records(records.map {|record|

                            {
                              'record' => record.to_hash(:trusted),
                              'uri' => record.uri
                            }
                          })
          end
        end

        checkpoints << [repository, type, start]
      end

      send_commit if did_something

      checkpoints.each do |repository, type, start|
        @state.set_last_mtime(repository.id, type, start)
      end
    end

    handle_deletes
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

