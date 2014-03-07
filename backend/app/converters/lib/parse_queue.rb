require 'tempfile'
require 'asutils'

module ASpaceImport

  # Manages the JSON object batch set
  class RecordBatch

    def initialize(opts = {})
      opts.each do |k,v|
        instance_variable_set("@#{k}", v)
      end

      @must_be_unique = ['subject']

      @record_filter = ->(record) { true }

      @uri_remapping = {}
      @seen_records = {}

      @working_file = opts[:working_file] || ASUtils.tempfile("import_batch_working_file")
      @working_area = []
    end


    def working_area
      @working_area
    end


    def <<(obj)
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


    def record_filter=(predicate)
      @record_filter = predicate
    end


    private

    def _push(obj)
      return unless @record_filter.call(obj)

      begin
        hash = obj.to_hash
      rescue JSONModel::ValidationException => e
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
