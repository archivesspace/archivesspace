require 'tempfile'

module ASpaceImport

  # Manages the JSON object batch set
  class RecordBatch
    attr_accessor :repo_id

    def initialize(opts = {})
      opts.each do |k,v|
        instance_variable_set("@#{k}", v)
      end

      @repo_id = Thread.current[:selected_repo_id]

      @must_be_unique = ['subject']

      @uri_remapping = {}
      @seen_records = {}

      @working_file = Tempfile.new("import_batch")
      @working_area = []

      if @dry
        @dry_response = Class.new do

          def initialize(map)
            @map = map
          end

          def code
            200
          end

          def read_body(&block)
            block.call("[\n")
            @map.each do |k, v|
              block.call(ASUtils.to_json({k => v}))
            end
            block.call("\n]")
          end
        end
      end
    end


    def working_area
      @working_area
    end


    def inspect
      @working_file.close
      str = "["
      File.open(@working_file.path).each do |line|
        puts "Reading line #{line}"
        str << "#{line.gsub(/\n/,'')},"
      end
      str << "]"
      str.sub!(/,\]\Z/, "]")

      @working_file.open

      arr = ASUtils.json_parse(str)
      "Working Area: " << @working_area.inspect <<  " --- Serialized Batch: " << arr.inspect
    end


    def <<(obj)
      @working_area.push(obj)
    end


    def flush
      while !@working_area.empty?
        flush_last
      end
    end


    def flush_last
      last = @working_area.pop
      if last.class.method_defined? :uri and !last.uri.nil?
        _push(last)
      end
    end       


    def save!
      unless @working_area.empty?
        flush
      end
      _save do |response|
        yield response
      end
    end


    private 

    def _push(obj)
      begin
        hash = obj.to_hash
      rescue JSONModel::ValidationException => e
        @log.debug("Invalid Object: #{obj.inspect}")
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


    def _save(&block)

      close

      begin
        if @dry
          if @batch_path
            FileUtils.copy_file(@batch_file.path, @batch_path)
          end
          batch = ASUtils.json_parse(File.open(@batch_file).read)

          mapping = {:saved => Hash[batch.map {|rec| [rec['uri'], [rec['uri'], JSONModel.parse_reference(rec['uri'])[:id]]] }] }
          response = @dry_response.new(mapping)

          block.call(response)
        else

          uri = "/repositories/#{@repo_id}/batch_imports"
          url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

          JSONModel::HTTP.with_request_priority(:low) do
            JSONModel::HTTP.post_json_file(url, @batch_file.path, &block)
          end
        end
      ensure
        @batch_file.unlink
      end
    end


    def close

      @working_file.close

      @batch_file = Tempfile.new("import_batch")

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
    end
  end
end
