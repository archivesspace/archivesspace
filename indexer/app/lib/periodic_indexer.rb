require_relative 'indexer_common'
require_relative 'index_state'
require_relative 'index_state_s3'
require 'time'
require 'thread'
require 'java'
require 'log'

# Eagerly load this constant since we access it from multiple threads.  Having
# two threads try to load it simultaneously seems to create the possibility for
# race conditions.
java.util.concurrent.TimeUnit::MILLISECONDS

class PeriodicIndexer < IndexerCommon

  def initialize(backend_url = nil, state = nil, indexer_name = nil, verbose = true)
    super(backend_url || AppConfig[:backend_url])

    @indexer_name = indexer_name || 'PeriodicIndexer'
    state_class = AppConfig[:index_state_class].constantize
    @state = state || state_class.new
    @verbose = verbose

    # A small window to account for the fact that transactions might be committed
    # after the periodic indexer has checked for updates, but with timestamps from
    # prior to the check.
    @window_seconds = 30

    @time_to_sleep = AppConfig[:solr_indexing_frequency_seconds].to_i
    @thread_count = AppConfig[:indexer_thread_count].to_i
    @records_per_thread = AppConfig[:indexer_records_per_thread].to_i

    # Space out our request threads a little, such that half the threads are
    # waiting on the backend while the other half are mapping documents &
    # indexing.
    concurrent_requests = (@thread_count <= 2) ? @thread_count : (@thread_count.to_f / 2).ceil
    @backend_fetch_sem = java.util.concurrent.Semaphore.new(concurrent_requests)

    @timing = IndexerTiming.new
  end

  WORKER_STATUS_NOTHING_INDEXED = 0
  WORKER_STATUS_INDEX_SUCCESS = 1
  WORKER_STATUS_INDEX_ERROR = 2

  def start_worker_thread(queue, record_type)
    repo_id = JSONModel.repository
    session = JSONModel::HTTP.current_backend_session

    Thread.new do
      # Each worker thread will yield a value (Thread.value) indicating either
      # "did nothing", "complete success" or "errors encountered".
      worker_status = WORKER_STATUS_NOTHING_INDEXED

      begin
        # Inherit the repo_id and user session from the parent thread
        JSONModel.set_repository(repo_id)
        JSONModel::HTTP.current_backend_session = session

        while true
          id_subset = queue.poll(10000, java.util.concurrent.TimeUnit::MILLISECONDS)

          # If the parent thread has finished, it should have pushed a :finished
          # token.  But if we time out after a reasonable amount of time, assume
          # it isn't coming back.
          break if (id_subset == :finished || id_subset.nil?)

          records = @timing.time_block(:record_fetch_ms) do
            @backend_fetch_sem.acquire
            begin
              # Happy path: we request all of our records in one shot and
              # everything goes to plan.
              begin
                fetch_records(record_type, id_subset, resolved_attributes)
              rescue
                worker_status = WORKER_STATUS_INDEX_ERROR

                # Sad path: the fetch failed for some reason, possibly because
                # one or more records are malformed and triggering a bug
                # somewhere.  Recover as best we can by fetching records
                # individually.
                salvaged_records = []

                id_subset.each do |id|
                  begin
                    salvaged_records << fetch_records(record_type, [id], resolved_attributes)[0]
                  rescue
                    # Not seeing new workers get started?
                    Log.error("Failed fetching #{record_type} id=#{id}: #{$!}")
                  end
                end

                salvaged_records
              end
            ensure
              @backend_fetch_sem.release
            end
          end

          if !records.empty?
            if worker_status == WORKER_STATUS_NOTHING_INDEXED
              worker_status = WORKER_STATUS_INDEX_SUCCESS
            end

            begin
              # Happy path: index all of our records in one shot
              index_records(records.map {|record|
                              {
                                'record' => record.to_hash(:trusted),
                                'uri' => record.uri
                              }
                            })
            rescue
              worker_status = WORKER_STATUS_INDEX_ERROR

              # Sad path: indexing of one or more records failed, possibly due
              # to weird data or bugs in mapping rules.  Index as much as we
              # can before reporting the error.
              records.each do |record|
                begin
                  index_records([
                                  {
                                    'record' => record.to_hash(:trusted),
                                    'uri' => record.uri
                                  }
                                ])
                rescue
                  Log.error("Failure while indexing record: #{record.uri}: #{$!}")
                  Log.exception($!)
                end
              end
            end
          end
        end

        worker_status
      rescue
        Log.error("Failure in #{@indexer_name} worker thread: #{$!}")
        Log.error($@.join("\n"))

        return WORKER_STATUS_INDEX_ERROR
      end
    end
  end


  def run_index_round
    log("Running index round")

    login

    # Index any repositories that were changed
    start = Time.now
    repositories = JSONModel(:repository).all('resolve[]' => resolved_attributes)

    modified_since = [@state.get_last_mtime('repositories', 'repositories') - @window_seconds, 0].max
    updated_repositories = repositories.reject {|repository| Time.parse(repository['system_mtime']).to_i < modified_since}.
    map {|repository| {
        'record' => repository.to_hash(:raw),
        'uri' => repository.uri
      }
    }

    # Indexing repos is usually easy, since its unlikely there will be lots of
    # them. Also, in case a repository has just been unpublished, delete PUI-only records
    if !updated_repositories.empty?
      index_records(updated_repositories)
      repositories_updated_action(updated_repositories)
      send_commit
      @state.set_last_mtime('repositories', 'repositories', start)
    end

    # And any records in any repositories
    repositories.each_with_index do |repository, i|
      next if !repository.publish and self.instance_of?(PUIIndexer)
      JSONModel.set_repository(repository.id)

      checkpoints = []

      record_types.each do |type|
        next if @@global_types.include?(type) && i > 0
        start = Time.now

        modified_since = [@state.get_last_mtime(repository.id, type) - @window_seconds, 0].max

        # we get all the ids of this record type out of the repo
        id_set = JSONModel::HTTP.get_json(JSONModel(type).uri_for, :all_ids => true, :modified_since => modified_since) || ''

        next if id_set.empty?

        indexed_count = 0

        work_queue = java.util.concurrent.LinkedBlockingQueue.new(@thread_count)

        workers = (0...@thread_count).map {|thread_idx|
          start_worker_thread(work_queue, type)
        }

        begin
          # Feed our worker threads subsets of IDs to process
          id_set.each_slice(@records_per_thread) do |id_subset|
            # This will block if all threads are currently busy indexing.
            while !work_queue.offer(id_subset, 5000, java.util.concurrent.TimeUnit::MILLISECONDS)
              # The work queue is full.  Threads might just be busy, but check
              # for failed workers too.

              # If any of the workers have caught an exception, rethrow it immediately
              workers.each do |thread|
                thread.value if thread.status.nil?
              end
            end

            indexed_count += id_subset.length
            log("~~~ Indexed #{indexed_count} of #{id_set.length} #{type} records in repository #{repository.repo_code}")
          end
        ensure
          # Once we're done, instruct the workers to finish up.
          @thread_count.times { work_queue.offer(:finished, 5000, java.util.concurrent.TimeUnit::MILLISECONDS) }
        end

        # If any worker reports that they indexed some records, we'll send a
        # commit.
        worker_statuses = workers.map {|thread|
            thread.join
            thread.value
        }

        # Commit if anything was added to Solr
        unless worker_statuses.all? {|status| status == WORKER_STATUS_NOTHING_INDEXED}
          send_commit
        end

        log("Indexed #{id_set.length} records in #{Time.now.to_i - start.to_i} seconds")

        if worker_statuses.include?(WORKER_STATUS_INDEX_ERROR)
          Log.info("Skipping update of indexer state for record type #{type} in repository #{repository.id} due to previous failures")          
        else
          @state.set_last_mtime(repository.id, type, start)
        end
      end

      index_round_complete(repository)
    end

    handle_deletes

    log("Index round complete")
  end

  def index_round_complete(repository)
    # Give subclasses a place to hang custom behavior.
  end

  def repositories_updated_action(updated_repositories)
    # Give subclasses a place to hang custom behavior.
  end


  def handle_deletes(opts = {})
    start = Time.now
    last_mtime = @state.get_last_mtime('_deletes', 'deletes')
    did_something = false

    page = 1
    while true
      deletes = JSONModel::HTTP.get_json("/delete-feed", :modified_since => [last_mtime - @window_seconds, 0].max, :page => page, :page_size => @records_per_thread)

      if !deletes['results'].empty?
        did_something = true
      end

      delete_records(deletes['results'], opts)

      break if deletes['last_page'] <= page

      page += 1
    end

    if did_something
      send_commit
      @state.set_last_mtime('_deletes', 'deletes', start)
    end
  end

  def run
    while true
      begin
        run_index_round unless paused?
      rescue
        reset_session
        Log.error($!.backtrace.join("\n"))
        Log.error($!.inspect)
      end

      sleep @time_to_sleep
    end
  end

  # used for just info lines
  def log(line)
    Log.info("#{@indexer_name} [#{Time.now}] #{line}")
  end

  def self.get_indexer(state = nil, name = "Staff Indexer")
    indexer = self.new(AppConfig[:backend_url], state, name)
  end

  def fetch_records(type, ids, resolve)
    JSONModel(type).all(:id_set => ids.join(","), 'resolve[]' => resolve)
  end

end
