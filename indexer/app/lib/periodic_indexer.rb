require_relative 'indexer_common'
require 'time'
require 'thread'
require 'java'
require 'singleton'

java_import 'java.util.concurrent.ThreadPoolExecutor'
java_import 'java.util.concurrent.TimeUnit'
java_import 'java.util.concurrent.LinkedBlockingQueue'
java_import 'java.util.concurrent.FutureTask'
java_import 'java.util.concurrent.Callable'

# Eagerly load this constant since we access it from multiple threads.  Having
# two threads try to load it simultaneously seems to create the possibility for
# race conditions.
java.util.concurrent.TimeUnit::MILLISECONDS

# a place for trees...
# not totaly sure how i feel about this...
class ProcessedTrees
  def self.instance
    # Temporary workaround for thread sharing.
    Thread.current[:indexer_tree_store] ||= java.util.concurrent.ConcurrentHashMap.new
  end
end

# we store the state of uri's index in the indexer_State directory
class IndexState

  def initialize(state_dir = nil)
    @state_dir = state_dir || File.join(AppConfig[:data_directory], "indexer_state")
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


## this is the task that will be called to run the indexer
class PeriodicIndexerTask
  include Callable
  
  def initialize(params)
    @params = params 
    @worker_class = PeriodicIndexerWorker
  end

  # how we run the worker
  def call
    @worker_class.new(@params).run
  end

end


# not really a worker...just some temp we hire to do a task
# we kill this guy after he's done his job ( don't tell him ) 
class PeriodicIndexerWorker < CommonIndexer

  # this is ugly
  def initialize(params)
    super(AppConfig[:backend_url])
    @state = params[:state] || IndexState.new
    @record_type = params[:record_type] || "repository"
    @id_set = params[:id_set] || [] 
    @repo_id = params[:repo_id] || "0"
    @session = params[:session]
    @indexed_count = params[:indexed_count] || 0 
  end
 
  # this was pulled from the original pindexer
  def load_tree_docs(tree, result, root_uri, path_to_root = [], index_whole_tree = false)
    return unless tree['publish']

    this_node = tree.reject {|k, v| k == 'children'}

    direct_children = tree['children'].
                        reject {|child| child['has_unpublished_ancestor'] || !child['publish'] || child['suppressed']}.
                        map {|child|
                          grand_children = child['children'].reject{|grand_child| grand_child['has_unpublished_ancestor'] || !grand_child['publish'] || grand_child['suppressed']}
                          child['has_children'] = !grand_children.empty?
                          child.reject {|k, v| k == 'children'}
                        }

    this_node['has_children'] = !direct_children.empty?

    doc = {
      'id' => "tree_view_#{tree['record_uri']}",
      'primary_type' => 'tree_view',
      'types' => ['tree_view'],
      'exclude_by_default' => 'true',
      'node_uri' => tree['record_uri'],
      'repository' => JSONModel.repository_for(tree['record_uri']),
      'root_uri' => root_uri,
      'publish' => true,
      'tree_json' => ASUtils.to_json(:self => this_node,
                                     :path_to_root => path_to_root,
                                     :direct_children => direct_children)
    }

    # For the root node, store a copy of the whole tree
    if index_whole_tree && path_to_root.empty?
      doc['whole_tree_json'] = ASUtils.to_json(tree)
    end

    result << doc
    doc = nil

    tree['children'].each do |child|
      load_tree_docs(child, result, root_uri, path_to_root + [this_node], index_whole_tree)
    end
  end

  # also pulled from the original pindexer
  def delete_trees_for(resource_uris)
    return if resource_uris.empty?

    resource_uris.each_slice(512) do |resource_uris|
      req = Net::HTTP::Post.new("#{solr_url.path}/update")
      req['Content-Type'] = 'application/json'

      escaped = resource_uris.map {|s| "\"#{s}\""}
      delete_request = {'delete' => {'query' => "primary_type:tree_view AND root_uri:(#{escaped.join(' OR ')})"}}

      req.body = delete_request.to_json

      response = do_http_request(solr_url, req)

      if response.code != '200'
        raise "Error when deleting record trees: #{response.body}"
      end
    end
  end


  # this is where we configure how the solr doc is generated
  def configure_doc_rules
    super

    add_batch_hook {|batch|
      records = batch.map {|rec|
        if ['resource', 'digital_object', 'classification'].include?(rec['primary_type'])
          rec['id']
        elsif rec['primary_type'] == 'archival_object'
          rec['resource']
        elsif rec['primary_type'] == 'digital_object_component'
          rec['digital_object']
        elsif rec['primary_type'] == 'classification_term'
          rec['classification']
        else
          nil
        end
      }.compact.uniq

      # Don't reprocess trees we've already covered during previous batches
      records -= ProcessedTrees.instance.keySet.to_a

      ## Each record needs its tree indexed

      # Delete any existing versions
      delete_trees_for(records)

      records.each do |record_uri|
        # To avoid all of the indexing threads hitting the same tree at the same
        # moment, use @processed_trees to ensure that only one of them handles
        # it.
        next if ProcessedTrees.instance.putIfAbsent(record_uri, true)

        record_data = JSONModel.parse_reference(record_uri)

        tree = JSONModel("#{record_data[:type]}_tree".intern).find(nil, "#{record_data[:type]}_id".intern => record_data[:id])

        load_tree_docs(tree.to_hash(:trusted), batch, record_uri, [],
                       ['classification'].include?(record_data[:type]))
        ProcessedTrees.instance.put(record_uri, true)
      end
    }
  end


  def fetch_records(type, ids, resolve)
    JSONModel(type).all(:id_set => ids.join(","), 'resolve[]' => resolve)
  end


  def run
    begin 
      t_0 = Time.now 

      if @session
        JSONModel::HTTP.current_backend_session = @session
      else
        login
      end

      JSONModel.set_repository(@repo_id)

      timing = IndexerTiming.new

      records = timing.time_block(:record_fetch_ms) do
        fetch_records(@record_type, @id_set, resolved_attributes)
      end

      return false if records.empty?

      index_records(records.map {|record|
                      {
                        'record' => record.to_hash(:raw),
                        'uri' => record.uri
                      }
                    },
                   timing)

      t_1 = Time.now

      timing.total = ((t_1 - t_0) * 1000.0)

      return [ records.length, timing, @indexed_count ] 
    
    rescue
      $stderr.puts("Failure in #{self.class} thread: #{$!}")
      $stderr.puts $!.backtrace
      raise $!
    end
  end

end

# this is the master who runs the tasks. also handles deletes and 'easy' tasks
# ( like indexing repositories ) . 
class PeriodicIndexer < CommonIndexer

  def initialize(state = nil, indexer_name)
    super(AppConfig[:backend_url])

    @indexer_name = indexer_name
    @state = state || IndexState.new

    # A small window to account for the fact that transactions might be committed
    # after the periodic indexer has checked for updates, but with timestamps from
    # prior to the check.
    @window_seconds = 30

    @time_to_sleep = AppConfig[:solr_indexing_frequency_seconds].to_i
    @thread_count = AppConfig[:indexer_thread_count].to_i
    @records_per_thread = AppConfig[:indexer_records_per_thread].to_i

    @task_class = PeriodicIndexerTask
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

    # indexing repos is usually easy, since its unlikely there will be lots of
    # them.
    if !updated_repositories.empty?
      index_records(updated_repositories)
      send_commit
    end

    @state.set_last_mtime('repositories', 'repositories', start)

    # Set the list of tree URIs back to empty to start over again
    ProcessedTrees.instance.clear    

    # And any records in any repositories
    repositories.each_with_index do |repository, i|
      JSONModel.set_repository(repository.id)

      did_something = false 

      # we roll through all our record types
      @@record_types.each do |type|
          
        next if @@global_types.include?(type) && i > 0
        start = Time.now

        modified_since = [@state.get_last_mtime(repository.id, type) - @window_seconds, 0].max

        # we get all the ids of this record type out of the repo
        id_set = JSONModel::HTTP.get_json(JSONModel(type).uri_for, :all_ids => true, :modified_since => modified_since)

        next if id_set.empty?

        indexed_count = 0
      
        # this will manage our treaded tasks
        executor = ThreadPoolExecutor.new(@thread_count, @thread_count, 5000, java.util.concurrent.TimeUnit::MILLISECONDS, LinkedBlockingQueue.new)
        tasks = []
        
        begin
          # lets take it one chunk ata time 
          id_set.each_slice(  @records_per_thread * @thread_count  ) do |id_subset|
            
            
            # now we load a task with the number of tasks 
            id_subset.each_slice(@records_per_thread) do |set|
              indexed_count += set.length
              task_order = { :repo_id => repository.id, 
                             :session => JSONModel::HTTP.current_backend_session,  
                             :record_type => type, 
                             :id_set => set, 
                             :state => @state,
                             :indexed_count => indexed_count
                            } 
              task = FutureTask.new( @task_class.new( task_order ) )
              
              # execute the task..
              executor.execute(task) 
              tasks << task 
            end  
           
            # we're blocking here until all the tasks are completed 
            tasks.map! do |t|
              count, time, counter = t.get
              next unless count # if the worker returned false, we move on
              log("~~~ Indexed #{counter} of #{id_set.length} #{type} records in repository #{repository.id} (added #{count.to_s} records in #{time.to_s}) ~~~")
              true 
            end

            # let's check if we did something, unless of course we alread know
            # we did something
            did_something ||= tasks.any? {|t| t } unless did_something 
            tasks.clear # clears the tasks.. 
          
          end # done iterating over ids
        ensure # Let us be sure that...
          # wnce we're done, we instruct the workers to finish up.
          executor.shutdown 
          # we also tell solr to commit
          send_commit if did_something
          # and lets make sure we clear this out too 
          ProcessedTrees.instance.clear    
        end


        # lets update the state...
        # moved this to update per each type since before it would only update
        # after completely finishing an entire repo ( so if you intterupted it,
        # you'd have to start all over again for each repo )
        @state.set_last_mtime(repository.id, type, start)

        log("~" * 100)
        log("~~~ Indexed #{id_set.length} #{type} records in #{Time.now.to_i - start.to_i} seconds ~~~")
        log("~" * 100)
      end # done iterating over types

      # courtesy flush for the repo 
      send_commit if did_something

    end # done iterating over repositories

    # now lets delete
    handle_deletes

    log("Index round complete")
  end

  def handle_deletes
    start = Time.now
    last_mtime = @state.get_last_mtime('_deletes', 'deletes')
    did_something = false

    page = 1
    while true
      deletes = JSONModel::HTTP.get_json("/delete-feed", :modified_since => [last_mtime - @window_seconds, 0].max, :page => page, :page_size => @records_per_thread)

      if !deletes['results'].empty?
        did_something = true
        deletes['results'] = deletes['results'].delete_if { |rec| rec.match(/(#{@@records_with_children.join('|')})/) }
      end

      delete_records(deletes['results'])

      break if deletes['last_page'] <= page

      page += 1
    end

    send_commit if did_something

    @state.set_last_mtime('_deletes', 'deletes', start)
  end

  def run
    while true
      begin
        run_index_round unless paused?
      rescue
        reset_session
        log($!.backtrace.join("\n"))
        log($!.inspect)
      end

      sleep @time_to_sleep
    end
  end

  def log(line)
    $stderr.puts("#{@indexer_name} [#{Time.now}] #{line}")
    $stderr.flush
  end

  def self.get_indexer(state = nil, name = "Staff Indexer")
    indexer = self.new(state, name)
  end

end
