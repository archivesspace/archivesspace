require 'java'
require 'json'
require 'tempfile'

class StreamingJsonReader
  attr_reader :count

  def initialize(filename)
    @filename = filename
    @count = nil
  end


  def each(determine_count = false)
    stream = java.io.FileReader.new(@filename)
    @count = 0 if determine_count

    begin
      mapper = org.codehaus.jackson.map.ObjectMapper.new

      # Skip the opening [
      stream.read

      parser = mapper.getJsonFactory.createJsonParser(stream)

      while parser.nextToken
        result = parser.readValueAs(java.util.Map.java_class)
        @count += 1 if determine_count
        yield(result)

        begin
          puts parser.nextToken
        rescue org.codehaus.jackson.JsonParseException
          # Skip over the pesky commas
        end
      end
    # rescue
    #   raise JSON::ParserError.new($!)

    ensure
      stream.close
    end
  end

end


class StreamingImport

  include JSONModel

  def initialize(stream, ticker)

    raise StandardError.new("Nothing to stream") unless stream

    @ticker = ticker

    with_status("Reading JSON records") do

      @ticker.tick_estimate = 1000 # this is totally made up, just want to show something

      @tempfile = Tempfile.new('import_stream')

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


  def process

    round = 0

    while true
      round += 1

      finished = true
      progressed = false

      with_status("Saving records: cycle #{round}") do
        @ticker.tick_estimate = @jstream.count
        @jstream.each do |rec|
          uri = rec['uri']
          dependencies = @dependencies[uri]

          if !@logical_urls[uri] && dependencies.all? {|d| @logical_urls[d]}
            # migrate it
            @logical_urls[uri] = do_create(rewrite(rec, @logical_urls))

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

      with_status("Dealing with circular dependencies: cycle #{round}") do
        if !progressed
          run_dependency_breaking_cycle
        end
      end
    end

    with_status("Cleaning up") do
      reattach_severed_limbs

      touch_toplevel_records

      cleanup
    end

    @logical_urls
  end


  private

  def load_logical_urls
    logical_urls = {}

    @ticker.tick_estimate = 20000; # made up

    @jstream.each(true) do |rec|

      if !rec['uri']
        raise ImportException.new(:invalid_object => to_jsonmodel(rec, false),
                                  :error => "Missing the temporary uri (required to set record relationships)")
      end

      logical_urls[rec['uri']] = nil

      # Take the opportunity to validate the record too
      to_jsonmodel(rewrite(rec, {}))

      @ticker.tick
    end

    logical_urls
  end


  def load_dependencies
    dependencies = {}
    position_offsets = {}

    @ticker.tick_estimate = @jstream.count

    position_maps = {}

    @jstream.each do |rec|
      dependencies[rec['uri']] = extract_logical_urls(rec, @logical_urls) - [rec['uri']]
      check_for_invalid_external_references(rec, @logical_urls)

      if rec['position']
        pos = rec['position']

        set_key = (rec['parent'] || rec['resource'] || rec['digital_object'])['ref']
        position_maps[set_key] ||= []
        position_maps[set_key][pos] ||= []
        position_maps[set_key][pos] << rec['uri']

      end

      @ticker.tick
    end

    position_maps.each do |set_key, positions|
      offset = 0
      positions.compact!
      while !positions.empty?
        first = positions.shift
        while first.length > 1
          offset += 1
          first_last = first.pop
          position_offsets[first_last] = offset
          dependencies[first_last] << first[0]
        end

        unless positions.empty?
          dependencies[positions[0][0]] << first[0] 
          position_offsets[positions[0][0]] = offset
        end
      end
    end

    return dependencies, position_offsets
  end


  def to_jsonmodel(record, validate = true)
    JSONModel(record['jsonmodel_type'].intern).from_hash(record, true, !validate)
  end


  def do_create(record, noerror = false)
    begin
      if record['position'] && @position_offsets[record['uri']]
        record['position'] += @position_offsets[record['uri']]
      end

      json = to_jsonmodel(record, true)

      model = model_for(record['jsonmodel_type'])

      obj = if model.respond_to?(:ensure_exists)
              model.ensure_exists(json, nil)
            else
              model_for(record['jsonmodel_type']).create_from_json(json)
            end

      Log.debug("Created: #{record['uri']}")

      obj.uri
    rescue
      if noerror
        nil
      else
        raise $!, "Problem creating '#{title_or_fallback(record)}': #{$!}"
      end
    end
  end


  def rewrite(record, logical_urls)
    ASpaceImport::Utils.update_record_references(record, logical_urls)
  end


  # Find a record that we're able to create by lopping off its properties causing
  # dependency cycles.  We'll reattach them with a separate update later.
  def run_dependency_breaking_cycle
    progressed = false

    @jstream.each do |rec|
      uri = rec['uri']

      next if @logical_urls[uri]

      missing_dependencies = @dependencies[uri].reject {|d| @logical_urls[d]}

      rec.keys.each do |k|
        if !extract_logical_urls(rec[k], missing_dependencies).empty?
          @limbs_for_reattaching[uri] ||= []
          @limbs_for_reattaching[uri] << [k, rec[k]]
          rec.delete(k)
        end
      end

      # Create the cut down record (which might fail)
      created_uri = do_create(rewrite(rec, @logical_urls), true)

      if created_uri
        # It worked!
        @logical_urls[uri] = created_uri

        progressed = true
        break
      end
    end

    raise "Can't progress any further.  Freaking out!" if !progressed
  end


  def reattach_severed_limbs
    @limbs_for_reattaching.each do |logical_uri, limbs|
      real_uri = @logical_urls[logical_uri]

      ref = JSONModel.parse_reference(real_uri)

      model = model_for(ref[:type])
      obj = model.get_or_die(ref[:id])

      json = model.to_jsonmodel(obj)

      limbs.each do |k, v|
        json[k.to_s] = rewrite(v, @logical_urls)
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
        if k != '_resolved'
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
