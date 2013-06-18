require_relative '../lib/jsonmodel_wrap'
require_relative '../lib/parse_queue'

module ASpaceImport

  def self.init
    Dir.glob(File.dirname(__FILE__) + '/../importers/*', &method(:load))
  end


  class Importer

    @@importers = {}


    def self.list
      list = "\nThe following importers are available\n"
      @@importers.each do |i, klass|
        list += "*#{i}* \n#{klass.profile}\n\n"
      end
      list
    end

    # @param options [Hash] runtime options passed into the importer
    # @return [Object] an instance of the selected importer
    # @raise [StandardError] if the class of the selected importer doesn't pass the usability test

    def self.create_importer(opts)
      i = @@importers[opts[:importer].to_sym]
      if !i.nil?
        i.new opts
      else
        raise StandardError.new("Unusable importer or importer not found for: #{name}(#{opts[:importer]})")
      end
    end

    def self.destroy_importers
      @@importers.each do |key, klass|
        Object.send(:remove_const, klass.name)
      end
      @@importers = {}
    end

    # @param name [Symbol] the key declared by importer being loaded
    # @param superclass [Const] a superfluous param in all likelihood
    # @param block [Block] the data-processing and self-describing methods defined by the importer, the meat of the importer
    # @return [Boolean]

    def self.importer(name, superclass = ASpaceImport::Importer, &block)
      if @@importers.has_key? name
        raise StandardError.new("Attempted to register #{name} a second time")
      else
        c = Class.new(superclass, &block)
        cname_prefix = name.to_s.split(/[_-]/).map {|i| i.capitalize }.join
        Object.const_set("#{cname_prefix}Importer", c)
        @@importers[name] = c
        true
      end
    end


    def initialize(opts = {})

      raise "Need a repo_id in order to run" unless opts[:repo_id]

      unless opts[:log]
        require 'logger'
        opts[:log] = Logger.new(STDOUT)

        if opts[:debug]
          opts[:log].level = Logger::DEBUG
        elsif opts[:quiet]
          opts[:log].level = Logger::UNKNOWN
        else
          opts[:log].level = Logger::WARN
        end
      end


      JSONModel::set_repository(opts[:repo_id])

      @flags = {}
      if opts[:importer_flags]
        opts[:importer_flags].each do |flag|
          @flags[flag] = true
        end
        opts.delete(:importer_flags)
      end

      opts.each do |k,v|
        instance_variable_set("@#{k}", v)
      end

      @block = nil
    end


    def run_safe(&block)

      @block = block
      return nil unless @block

      begin
        cache = self.run
        cache.save! do |response|
          handle_save_response(response)
        end
      rescue JSONModel::ValidationException => e

        errors = e.errors.collect.map{|attr, err| "#{e.invalid_object.class.record_type}/#{attr} #{err.join(', ')}"}
        @block.call({"errors" => errors})
      end
    end


    private

    def run
      ASpaceImport::ImportCache.new({:log => @log, :dry => @dry, :batch_path => @batch_path})
    end


    def handle_save_response(response)
      if response.code.to_s == '200'
        fragments = ""
        response.read_body do |message|
          begin
            if message =~ /\A\[\n\Z/
              # do nothing because we're treating the response as a stream
            elsif message =~ /\A\n\]\Z/
              # the last message doesn't have a comma, so it's a fragment
              message = ASUtils.json_parse(fragments.sub(/\n\Z/, ''))
              send_to_client(message)
            elsif message =~ /.*,\n\Z/
              message = ASUtils.json_parse(fragments + message.sub(/,\n\Z/, ''))
              send_to_client(message)
            else
              fragments << message
            end
          rescue JSON::ParserError => e
            send_to_client({'error' => e.to_s})
          end
        end

      else
        send_to_client({"error" => "Server Error #{response.code}"})
      end
    end


    def send_to_client(message)
      if @block
        @block.call(message)
      end
    end


    def emit_status(hsh)
      @block.call({'status' => [hsh]})
    end

  end
end

