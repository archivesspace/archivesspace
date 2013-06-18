require 'tempfile'

module ASpaceImport


  # Manages the JSON object batch set

  class Batch
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


    def push(obj)
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


    def save(&block)

      close

      begin
        if @dry
          if @batch_path
            FileUtils.copy_file(@batch_file.path, @batch_path)
          end
          batch = ASUtils.json_parse(File.open(@batch_file).read)

          # @log.debug("Posted file contents: #{batch.inspect}")

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


    private

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


  class ImportCache < Array

    def initialize(opts)
      @batch = Batch.new(opts)
      opts.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end


    def pop
      if self.last.class.method_defined? :uri and !self.last.uri.nil?
        @batch.push(self.last) unless self.last.uri.nil?
      end

      super
    end


    def clear!
      self.write!
    end


    def write!
      while !self.empty?
        self.pop
      end

      self
    end


    def save!(&block)
      unless self.empty?
        @log.warn("Saving objects that were not explicitly cleared from the cache")
        self.clear!
      end
      @batch.save(&block)
    end


    def inspect
      "Import Cache: " << super <<  " --- Batch: " << @batch.inspect
    end

  end
end



