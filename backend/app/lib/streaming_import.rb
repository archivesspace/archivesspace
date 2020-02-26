require 'java'
require 'json'
require 'atomic'
require 'tempfile'

require_relative 'dependency_set'
require_relative 'streaming_json_reader'
require_relative 'cycle_finder'
require_relative 'pooled_executor'


require 'pp'

class StreamingImport

  include JSONModel

  def initialize(stream, ticker, import_canceled = false,  migration = false)
    
    @import_canceled = import_canceled ? import_canceled :  Atomic.new(false)
    @migration = migration ? Atomic.new(true) : Atomic.new(false)
   
    raise StandardError.new("Nothing to stream") unless stream

    @ao_positions = {}

    @ticker = ticker

    with_status("Reading JSON records") do

      @ticker.tick_estimate = 1000 # this is totally made up, just want to show something

      @tempfile = ASUtils.tempfile('import_stream')

      begin
        while !(buf = stream.read(4096)).nil?
          @tempfile.write(buf)
          ticker.tick
        end
      ensure
        @tempfile.close
      end

    end

    @jstream = StreamingJsonReader.new(@tempfile.path)

    if @jstream.empty?
      @ticker.log("No records were found in the input file!")
    end

    if ASUtils.migration_mode?
      with_status("Creating any enumeration values that need to be there") do
        count = 0
        @jstream.each do |record|
          MigrationHelpers.walk_hash_with_schema(record, JSONModel.JSONModel(record['jsonmodel_type'].intern).schema,
                                                 proc {|record, schema|
                                                   schema['properties'].each do |property, schema_def|
                                                     if schema_def['dynamic_enum'] && record[property]

                                                       if record['jsonmodel_type'] =~ /series_system.*relationship/
                                                         relator_enum = JSONModel(record['jsonmodel_type'].intern).schema['properties']['relator']['dynamic_enum']

                                                         acceptable_values = BackendEnumSource.values_for(relator_enum)
                                                         unless acceptable_values.include?(record[property])
                                                           $stderr.puts("WARNING: enum value '#{record[property]}' isn't a valid value for #{relator_enum}")
                                                           $stderr.puts("Acceptable values are: #{acceptable_values.inspect}")
                                                         end
                                                       end

                                                       BackendEnumSource.valid?(schema_def['dynamic_enum'], record[property])
                                                     end
                                                   end

                                                   record
                                                 })

          count += 1
          if (count % 1000) == 0
            puts "Up to: #{count}"
          end
        end
      end
    end

    if ASUtils.migration_mode?
      with_status("Calculating AO positions") do
        resource_counters = {}

        @jstream.each do |record|
          next unless record['jsonmodel_type'] == 'archival_object'

          resource_counters[record['resource']['ref']] ||= 0
          resource_counters[record['resource']['ref']] += 1000

          @ao_positions[record['uri']] = resource_counters[record['resource']['ref']]
        end
      end
    end

    with_status("Validating records and checking links") do
      @logical_urls = load_logical_urls
    end

    with_status("Evaluating record relationships") do
      @dependencies, @position_offsets = load_dependencies
    end

    @limbs_for_reattaching = {}
  end


  def created_records
    @logical_urls.reject {|k, v| v.nil?}
  end


  def abort_if_import_canceled
    if @import_canceled.value
      @ticker.log("Import canceled!")
      raise ImportCanceled.new
    end
  end

  class MigrationRAPStore

    def initialize(jstream)
      @jstream = jstream
      @index = {}
      @tempfile = Tempfile.new("rapstore")

      build!
    end

    def build!
      offset = 0
      @jstream.each do |rec|
        next unless rec['jsonmodel_type'] == 'rap'

        attached_to = rec.delete('attached_to')

        # Don't need these now
        rec.delete('uri')
        rec.delete('id')

        json_str = ASUtils.to_json(rewrite(rec, {}, nil))
        @index[attached_to['ref']] = offset

        @tempfile.write(json_str)
        @tempfile.write("\n")

        offset += json_str.bytesize + 1
      end

      @tempfile.flush
    end

    def lookup(import_ref)
      offset = @index[import_ref]

      return nil unless offset

      @tempfile.seek(offset, :SET)
      rap = @tempfile.readline

      ASUtils.json_parse(rap)
    end

    # Copypasta
    def rewrite(record, logical_urls, root_uri)
      ASpaceImport::Utils.update_record_references(record, logical_urls, root_uri)
    end


  end


  def process_migration_mode
    round = 0
    finished = true

    begin
      with_status("Looking for cyclic relationships") do
        uris_causing_cycles = []

        CycleFinder.new(@dependencies, @ticker).each do |cycle_uri|
          uris_causing_cycles << cycle_uri unless uris_causing_cycles.include?(cycle_uri)
        end

        create_records_without_relationships(uris_causing_cycles)
      end

      rap_store = MigrationRAPStore.new(@jstream)

      # Now we know our data is acyclic, we can run rounds without thinking
      # about it.
      while true
        round += 1

        finished = true
        progressed = false

        with_status("Saving records: cycle #{round}") do
          created_uri_map = java.util.concurrent.ConcurrentHashMap.new
          worker_failed = java.util.concurrent.atomic.AtomicBoolean.new(false)

          pool = PooledExecutor.new(thread_count: 12,
                                    queue_size: 1024,
                                    request_context: RequestContext.dump) do |db, work|
            record = work[:record]
            logical_uri = work[:logical_uri]
            logical_urls = work[:logical_urls]

            begin
              DB.open(true) do
                do_create(rewrite(record, logical_urls, logical_uri), created_uri_map)
              end
            rescue
              $stderr.puts("FAILURE SAVING RECORD: #{$!}")
              $stderr.puts($@.join("\n"))
              worker_failed.set(true)
              raise
            end
          end

          @ticker.tick_estimate = @jstream.count
          @jstream.each do |rec|
            abort_if_import_canceled

            # We'll handle these ourselves
            next if rec['jsonmodel_type'] == 'rap'

            uri = rec['uri']
            dependencies = @dependencies[uri]

            if !@logical_urls[uri] && dependencies.all? {|d| @logical_urls[d]}
              if @ao_positions[uri]
                rec['position'] = @ao_positions[uri]
              end

              if rap = rap_store.lookup(rec['uri'])
                if rap['open_access_metadata']
                  rap['access_category'] = 'All public records'
                else
                  rap['access_category'] = 'N/A'
                end

                rec['rap_attached'] = rap
              end

              # migrate it
              pool.submit({record: rec, logical_uri: uri, logical_urls: @logical_urls})

              # Now that it's created, we don't need to see the JSON record for
              # this again either.  This will speed up subsequent cycles.
              @jstream.delete_current

              progressed = true
            end

            if !@logical_urls[uri]
              finished = false
            end

            @ticker.tick
          end

          pool.shutdown

          if worker_failed.get
            raise "Hit errors while creating records.  Migration can't continue--check logs for details."
          end


          # Merge created URIs
          created_uri_map.each do |uri, created_uri|
            @logical_urls[uri] = created_uri
          end
        end


        if finished
          break
        end

        if !progressed
          raise "Failed to make any progress on the current import cycle.  This shouldn't happen!"
        end
      end

    rescue
      $stderr.puts("UNEXPECTED ERROR: #{$!}")
      $stderr.puts($@.join("\n"))
      raise
    ensure
      with_status("Cleaning up") do
        if finished
          reattach_severed_limbs
          touch_toplevel_records
        end

        cleanup
      end
    end

    @logical_urls
  end


  def process

    round = 0
    finished = true

    begin
      with_status("Looking for cyclic relationships") do
        uris_causing_cycles = []

        CycleFinder.new(@dependencies, @ticker).each do |cycle_uri|
          uris_causing_cycles << cycle_uri unless uris_causing_cycles.include?(cycle_uri)
        end

        create_records_without_relationships(uris_causing_cycles)
      end

      # Now we know our data is acyclic, we can run rounds without thinking
      # about it.
      while true
        round += 1

        finished = true
        progressed = false

        with_status("Saving records: cycle #{round}") do
          @ticker.tick_estimate = @jstream.count
          @jstream.each do |rec|
            abort_if_import_canceled

            uri = rec['uri']
            dependencies = @dependencies[uri]

            if !@logical_urls[uri] && dependencies.all? {|d| @logical_urls[d]}
              # migrate it
              do_create(rewrite(rec, @logical_urls, uri), @logical_urls)

              # Now that it's created, we don't need to see the JSON record for
              # this again either.  This will speed up subsequent cycles.
              @jstream.delete_current

              progressed = true
            end

            if !@logical_urls[uri]
              finished = false
            end

            @ticker.tick
          end
        end

        if finished
          break
        end

        if !progressed
          raise "Failed to make any progress on the current import cycle.  This shouldn't happen!"
        end
      end

    ensure
      with_status("Cleaning up") do
        if finished
          reattach_severed_limbs
          touch_toplevel_records
        end

        cleanup
      end
    end

    @logical_urls
  end


  private

  def load_logical_urls
    logical_urls = {}

    @ticker.tick_estimate = @jstream.determine_count

    @jstream.each do |rec|

      if !rec['uri']
        raise ImportException.new(:invalid_object => to_jsonmodel(rec, false),
                                  :error => "Missing the temporary uri (required to set record relationships)")
      end

      logical_urls[rec['uri']] = nil

      if rec['jsonmodel_type'] == 'archival_object'
        # Might contain representations with their own logical URLs.  Deal with those as well.
        ['physical_representations', 'digital_representations'].each do |rep_type|
          Array(rec[rep_type]).each do |rep|
            if rep['uri']
              logical_urls[rep['uri']] = nil
            end
          end
        end
      end

      unless AppConfig.has_key?(:migration_skip_validate) && AppConfig[:migration_skip_validate]
        begin
          # Take the opportunity to validate the record too
          to_jsonmodel(rewrite(rec, {}, nil))
        rescue
          $stderr.puts("*** THIS RECORD FAILED TO VALIDATE (#{$!}")
          $stderr.puts(rec.pretty_inspect)

          raise $!
        end
      end

      @ticker.tick
    end

    logical_urls
  end


  def load_dependencies
    dependencies = DependencySet.new
    position_offsets = {}

    @ticker.tick_estimate = @jstream.count

    position_maps = {}

    @jstream.each do |rec|

      # Add this record's references as dependencies
      extract_logical_urls(rec, @logical_urls).each do |dependency|
        unless dependency == rec['uri']
          dependencies.add_dependency(rec['uri'], dependency)
        end
      end

      check_for_invalid_external_references(rec, @logical_urls)

      if rec['position']
        pos = rec['position']
        set_key = (
          rec['parent'] || rec['resource'] || rec['digital_object'] || rec['classification']
        )['ref']
        position_maps[set_key] ||= []
        position_maps[set_key][pos] ||= []
        position_maps[set_key][pos] << rec['uri']

      end

      @ticker.tick
    end

    position_maps.each do |set_key, positions|
      offset = 0
      positions.flatten!
      positions.compact!
      while !positions.empty?
        preceding = positions.shift
        following = positions[0]

        unless positions.empty?
          dependencies.add_dependency(following, preceding)
        end
      end
    end

    return dependencies, position_offsets
  end


  def to_jsonmodel(record, validate = true)
    JSONModel(record['jsonmodel_type'].intern).from_hash(record, true, !validate)
  end


  def assert_no_import_uris!(rec)
    if rec.is_a?(Hash)
      assert_no_import_uris!(rec.values)
    elsif rec.is_a?(JSONModelType)
      assert_no_import_uris!(rec.to_hash(:trusted))
    elsif rec.is_a?(Array)
      rec.each do |elt|
        assert_no_import_uris!(elt)
      end
    elsif rec.is_a?(String)
      if rec =~ ASpaceImport::Utils::IMPORT_ID_REGEX
        raise "Found unresolved import ID: #{rec}"
      end
    elsif rec.is_a?(Integer)
    elsif [nil, true, false].include?(rec)
    else
      raise "Was not expecting type: #{rec.class} of #{rec}"
    end
  end


  def do_create(record, logical_urls, noerror = false)
    begin
      if record['position'] && @position_offsets[record['uri']]
        record['position'] += @position_offsets[record['uri']]
      end

      needs_validate = !ASUtils.migration_mode?

      json = to_jsonmodel(record, needs_validate)

      # This will contain the import URI, but it's ignored anyway.
      logical_uri = json['uri']
      json['uri'] = nil

      # If we're creating an AO with some physical representations, note their logical URIs now.
      nested_representations = {}
      if json['jsonmodel_type'] == 'archival_object'
        ['physical_representations', 'digital_representations'].each do |rep_type|
          Array(json[rep_type]).each_with_index do |rep, idx|
            if rep['uri']
              nested_representations[rep_type] ||= {}
              nested_representations[rep_type][idx] = rep['uri']
              rep.delete('uri')
            end
          end
        end
      end

      begin
        assert_no_import_uris!(json)
      rescue
        $stderr.puts("FAILURE on #{json.inspect}")
        $stderr.puts("ERROR was: #{$!}")
        raise $!
      end

      model = model_for(record['jsonmodel_type'])

      obj = if model.respond_to?(:ensure_exists)
              model.ensure_exists(json, nil)
            else
              model_for(record['jsonmodel_type']).create_from_json(json, :migration => @migration )
            end

      @ticker.log("Created: #{record['uri']}")

      # Top-level record
      logical_urls[logical_uri] = obj.uri

      # And any representations
      unless nested_representations.empty?
        DB.open do |db|
          db[:physical_representation].filter(:archival_object_id => obj.id).order(:id).select(:repo_id, :id).all.each_with_index do |physrep, idx|
            if logical_uri = nested_representations.fetch('physical_representations', {})[idx]
              physical_uri = JSONModel(:physical_representation).uri_for(physrep[:id], :repo_id => physrep[:repo_id])
              logical_urls[logical_uri] = physical_uri
            end
          end

          db[:digital_representation].filter(:archival_object_id => obj.id).order(:id).select(:repo_id, :id).all.each_with_index do |digrep, idx|
            if logical_uri = nested_representations.fetch('digital_representations', {})[idx]
              physical_uri = JSONModel(:digital_representation).uri_for(digrep[:id], :repo_id => digrep[:repo_id])
              logical_urls[logical_uri] = physical_uri
            end
          end
        end
      end

      true
    rescue
      if noerror
        nil
      else
        raise $!, "Problem creating '#{title_or_fallback(record)}': #{$!}"
      end
    end
  end


  def rewrite(record, logical_urls, root_uri)
    ASpaceImport::Utils.update_record_references(record, logical_urls, root_uri)
  end


  # Create a selection of records (identified by URI) that are known to cause
  # dependency cycles.  We detach their relationships with other records and
  # reattach them at the end.
  #
  # This gets us around chicken-and-egg problems of two records with mutual
  # relationships.
  def create_records_without_relationships(record_uris)
    @jstream.each do |rec|
      uri = rec['uri']
      next unless record_uris.include?(uri)

      missing_dependencies = @dependencies[uri].reject {|d| @logical_urls[d]}

      if !missing_dependencies.empty?
        rec.keys.each do |k|
          if !extract_logical_urls(rec[k], missing_dependencies).empty?
            @limbs_for_reattaching[uri] ||= []
            @limbs_for_reattaching[uri] << [k, rec[k]]
            rec.delete(k)
          end
        end
      end

      # Create the cut down record--we'll put its relationships back later

      if do_create(rewrite(rec, @logical_urls, uri), @logical_urls, true)
        # Success!
      else
        raise "Failed to import the record #{uri} without its dependencies." +
              "  Since it contains circular dependencies with other records, the import cannot continue."
      end
    end
  end


  def reattach_severed_limbs
    @limbs_for_reattaching.each do |logical_uri, limbs|
      real_uri = @logical_urls[logical_uri]

      ref = JSONModel.parse_reference(real_uri)

      model = model_for(ref[:type])
      obj = model.get_or_die(ref[:id])

      json = model.to_jsonmodel(obj)

      limbs.each do |k, v|
        if json[k.to_s].is_a?(Array) || json[k.to_s].respond_to?(:to_array)
          json[k.to_s] = json[k.to_s].to_a

          # It's possible that the record we're reattaching relationships to
          # actually had some relationships added between when we lopped them
          # off and now.
          #
          # For example:
          #  * record A relates to [B, C]
          #
          #  * record A has those relationships detached to break cyclic dependencies
          #
          #  * record A is created without the relationships
          #
          #  * record D creates created, relating to [A]
          #
          #  * now, record A has its relationships attached.  Since the
          #    relationship is reciprocal, its true list of relationships should
          #    be [B, C, D], but if we just blindly overwrite with the list we
          #    stored originally, we'll lose that relationship with D.
          #
          # To avoid losing that relationship, we just merge the lists and dedupe the relationships.
          json[k.to_s] += rewrite(v, @logical_urls, logical_uri)
          json[k.to_s] = json[k.to_s].uniq
        else
          # The same thing can happen in the 1:1 relationship case too.  We just
          # sanity check things by making sure that, if the relationship was
          # added through the reciprocal relationship with another record, we
          # agree on who we're relating to.
          ref = rewrite(v, @logical_urls, logical_uri)

          if json[k.to_s] && json[k.to_s] != ref
            raise "Assertion failed: expected relationship #{ref.inspect} to match #{json[k.to_s]} but they differ!" +
                  "  This shouldn't happen, since it suggests that A thinks it relates to B, but C thinks it relates to A." +
                  "  No love triangles allowed!"
          end

          json[k.to_s] = ref
        end
      end

      cleaned = JSONModel(json.class.record_type).from_hash(json.to_hash)
      obj.update_from_json(cleaned)
    end
  end


  # If 'record' contains references to records outside of the current
  # repository, blow up.
  def check_for_invalid_external_references(record, logical_urls)
    if record.respond_to?(:to_array)
      record.each {|e| check_for_invalid_external_references(e, logical_urls)}
    elsif record.respond_to?(:each)
      record.each do |k, v|
        if k == 'ref' && !logical_urls.has_key?(v)
          URIResolver.ensure_reference_is_valid(v, RequestContext.get(:repo_id))
        elsif k != '_resolved'
          check_for_invalid_external_references(v, logical_urls)
        end
      end
    end
  end


  # A ref is any string that appears in our working set of logical_urls
  def extract_logical_urls(record, logical_urls)
    if record.respond_to?(:to_array)
      record.map {|e| extract_logical_urls(e, logical_urls)}.flatten(1)
    elsif record.respond_to?(:each)
      refs = []

      record.each do |k, v|
        if k != '_resolved' && k != 'uri'
          refs += extract_logical_urls(v, logical_urls)
        end
      end

      refs
    else
      if logical_urls.include?(record)
        [record]
      else
        []
      end
    end
  end


  def model_for(jsonmodel_type)
    Kernel.const_get(jsonmodel_type.to_s.camelize)
  end


  def touch_toplevel_records
    # We want the records we've created to be picked up by the periodic indexer,
    # but it's possible that some reasonable amount of time has elapsed between
    # when the record was created (and its mtime set) and when the whole
    # transaction is committed.
    #
    # So, do some sneaky updates here to set the mtimes to right now.
    #
    # Note: Under Derby (where imports run without transactions), this has a
    # pretty good chance of deadlocking with an indexing thread that is
    # currently trying to index these records.  But since Derby imports aren't
    # running within a transaction, we don't care anyway!

    if DB.supports_mvcc?
      records_by_type = {}

      @logical_urls.values.compact.each do |uri|
        ref = JSONModel.parse_reference(uri)

        records_by_type[ref[:type]] ||= []
        records_by_type[ref[:type]] << ref[:id]
      end

      records_by_type.each do |type, ids|
        model = model_for(type)
        model.update_mtime_for_ids(ids)
      end
    end
  end


  def cleanup
    if @tempfile
      @tempfile.unlink
    end
  end


  def with_status(stat, &block)
    @status_id ||= 0
    @status_id += 1

    status = {:id => @status_id, :label => stat}

    @ticker.status_update(:started, status)
    result = block.call
    @ticker.status_update(:done, status)

    result
  end


  def title_or_fallback(record)
    record['title'] ? record['title'] : record['jsonmodel_type']
  end
end
