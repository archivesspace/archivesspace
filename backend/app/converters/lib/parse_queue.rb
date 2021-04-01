require 'tempfile'
require 'asutils'

module ASpaceImport

  FIELDS_TO_DEDUPE = [:dates]

  # Manages the JSON object batch set
  class RecordBatch

    def initialize(opts = {})
      opts.each do |k, v|
        instance_variable_set("@#{k}", v)
      end

      @must_be_unique = ['subject']

      @record_filter = ->(record) { true }

      @uri_remapping = {}
      @seen_records = {}

      @working_file = opts[:working_file] || ASUtils.tempfile("import_batch_working_file")
      @working_area = []
    end


    def self.dedupe_subrecords(obj)
      ASpaceImport::FIELDS_TO_DEDUPE.each do |subrecord|

        if obj.respond_to?(subrecord) && obj.send(subrecord).is_a?(Array)
          hashes = []
          obj.send(subrecord).map! { |json|
            hash = json.to_hash.hash
            if hashes.include?(hash)
              nil
            else
              hashes << hash
              json
            end
          }

          obj.send(subrecord).compact!
        end
      end
    end


    def working_area
      @working_area
    end


    def <<(obj)
      self.class.dedupe_subrecords(obj)

      raise "Imported object can't be nil!" unless obj

      # If the record's JSON schema contains a URI (i.e. this is a top-level
      # record), then blow up if it isn't provided.
      if obj.class.is_a?(JSONModelType) && obj.class.schema['uri'] && !obj.uri
        Log.debug("Can't import object: #{obj.inspect}")
        raise "Imported object must have a URI!"
      end

      @working_area.push(obj)
    end


    def flush
      while !@working_area.empty?
        flush_last
      end
    end


    # This URI check stops regular JSONModels from going through.  JSONModelWrap
    # is what puts that here...
    def flush_last
      last = @working_area.pop

      if last.class.method_defined? :uri and !last.uri.nil?
        _push(last)
      end
    end


    def get_output_path
      close
      @batch_file.path
    end


    def each_open_file_path
      yield @working_file.path if @working_file && @working_file.path
      yield @batch_file.path if @batch_file && @batch_file.path
    end


    def record_filter=(predicate)
      @record_filter = predicate
    end


    private

    def _push(obj)
      return unless @record_filter.call(obj)

      begin
        hash = obj.to_hash
      rescue JSONModel::ValidationException => e
        e.import_context = obj["import_context"]
        raise e
      end

      if @must_be_unique.include?(hash['jsonmodel_type'])
        hash_code = hash.clone.tap {|h| h.delete("uri")}.hash

        if @seen_records[hash_code]
          # Duplicate detected.  Map this record's URI back to the first instance we saw.
          @uri_remapping[hash['uri']] = @seen_records[hash_code]
          return
        else
          @seen_records[hash_code] = hash['uri']
        end
      end
      @working_file.write(ASUtils.to_json(hash))
      @working_file.write("\n")
    end


    def close
      return if @closed
      flush
      @working_file.close

      @batch_file = ASUtils.tempfile("import_batch_result")

      @batch_file.write("[")

      uris = []
      File.open(@working_file.path).each_with_index do |line, i|
        @batch_file.write(",") unless i == 0

        rec = ASUtils.json_parse(line)
        rec = ASpaceImport::Utils.update_record_references(rec, @uri_remapping)

        uris << rec['uri']

        @batch_file.write(ASUtils.to_json(rec))
      end

      @working_file.unlink

      @batch_file.write("]")
      @batch_file.close
      @closed = true
    end
  end
end
