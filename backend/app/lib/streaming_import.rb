require 'java'
require 'json'
require 'tempfile'

class StreamingJsonReader

  def initialize(filename)
    @filename = filename
  end


  def each
    stream = java.io.FileReader.new(@filename)

    begin
      mapper = org.codehaus.jackson.map.ObjectMapper.new

      # Skip the opening [
      stream.read

      parser = mapper.getJsonFactory.createJsonParser(stream)

      while parser.nextToken
        result = parser.readValueAs(java.util.Map.java_class)
        yield(result)

        begin
          puts parser.nextToken
        rescue org.codehaus.jackson.JsonParseException
          # Skip over the pesky commas
        end
      end
    rescue
      raise JSON::ParserError.new($!)
    ensure
      stream.close
    end
  end

end


class StreamingImport

  include JSONModel

  def initialize(stream)

    @tempfile = Tempfile.new('import_stream')

    begin
      while !(buf = stream.read(4096)).nil?
        @tempfile.write(buf)
      end
    ensure
      @tempfile.close
    end

    @json = StreamingJsonReader.new(@tempfile.path)

    @logical_urls = load_logical_urls
    @dependencies = load_dependencies

    @limbs_for_reattaching = {}
  end


  def process
    round = 0

    while true
      round += 1
      finished = true
      progressed = false

      @json.each do |rec|
        uri = rec['uri']
        dependencies = @dependencies[uri]

        if !@logical_urls[uri] && dependencies.all? {|d| @logical_urls[d]}
          # migrate it
          @logical_urls[uri] = do_create(rewrite(rec, @logical_urls))

          if !@logical_urls[uri]
            raise "Unexpected failure in #{uri}.  Aborting!"
          end

          progressed = true
        end

        if !@logical_urls[uri]
          finished = false
        end
      end

      if finished
        break
      end

      if !progressed
        run_dependency_breaking_cycle
      end
    end

    reattach_severed_limbs

    touch_toplevel_records

    cleanup

    $stderr.puts "Finished in #{round} rounds"
  end


  private

  def load_logical_urls
    logical_urls = {}

    @json.each do |rec|
      logical_urls[rec['uri']] = nil

      # Take the opportunity to validate the record too
      to_jsonmodel(rewrite(rec, {}))
    end

    logical_urls
  end


  def load_dependencies
    dependencies = {}

    @json.each do |rec|
      dependencies[rec['uri']] = extract_refs(rec, @logical_urls) - [rec['uri']]
    end

    dependencies
  end


  def to_jsonmodel(record, validate = true)
    JSONModel(record['jsonmodel_type'].intern).from_hash(record, true, !validate)
  end


  def do_create(record, validate = true)
    begin
      json = to_jsonmodel(record, validate)

      RequestContext.open(:current_username => "admin") do
        obj = model_for(record['jsonmodel_type']).create_from_json(json)
        $stderr.puts "migrated: #{record['uri']}"

        obj.uri
      end
    rescue
      nil
    end
  end


  def rewrite(record, logical_urls)
    if record.respond_to?(:to_array)
      record.map {|e| rewrite(e, logical_urls)}
    elsif record.respond_to?(:each)
      fixed = {}

      record.each do |k, v|
        fixed[k] = rewrite(v, logical_urls)
      end

      fixed
    else
      logical_urls[record] || record
    end
  end


  # Find a record that we're able to create by lopping off its properties causing
  # dependency cycles.  We'll reattach them with a separate update later.
  def run_dependency_breaking_cycle
    progressed = false

    @json.each do |rec|
      uri = rec['uri']

      next if @logical_urls[uri]

      missing_dependencies = @dependencies[uri].reject {|d| @logical_urls[d]}

      rec.keys.each do |k|
        if !extract_refs(rec[k], missing_dependencies).empty?
          @limbs_for_reattaching[uri] ||= []
          @limbs_for_reattaching[uri] << [k, rec[k]]
          rec.delete(k)
        end
      end

      # Create the cut down record (which might fail)
      created_uri = do_create(rewrite(rec, @logical_urls))

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

      obj.update_from_json(json)
    end
  end


  # A ref is any string that appears in our working set of logical_urls
  def extract_refs(record, logical_urls)
    if record.respond_to?(:to_array)
      record.map {|e| extract_refs(e, logical_urls)}.flatten(1)
    elsif record.respond_to?(:each)
      refs = []

      record.each do |k, v|
        if k != '_resolved'
          refs += extract_refs(v, logical_urls)
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

end
