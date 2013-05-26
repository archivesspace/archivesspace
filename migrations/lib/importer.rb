require_relative '../lib/jsonmodel_wrap'
require_relative '../lib/parse_queue'  
require 'csv'

module ASpaceImport
  
  def self.init
    Dir.glob(File.dirname(__FILE__) + '/../importers/*', &method(:load))
  end
  

  class Importer

    @@importers = {}
    attr_accessor :parse_queue
    attr_reader :error_log

    def self.list
      list = "The following importers are available\n"
      @@importers.each do |i, klass|
        list += "\t #{klass.name} \t #{klass.profile}\n"
      end
      list
    end

    # @param options [Hash] runtime options passed into the importer
    # @return [Object] an instance of the selected importer
    # @raise [StandardError] if the class of the selected importer doesn't pass the usability test

    def self.create_importer(opts)
      i = @@importers[opts[:importer].to_sym]
      if !i.nil? && i.usable
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

    def self.usable
      true
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
      
      # @log.debug("Importer Flags: #{@flags}")
      
      @error_log = []
      @block = nil

      @parse_queue = ASpaceImport::ParseQueue.new(opts)
    end

    
    def parse_queue
      @parse_queue
    end


    def send_to_client(message)
      if @block
        @block.call(message)
      end
    end


    def save_all
      parse_queue.save do |response|
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
    end
  
    
    def report_summary
      @import_summary
    end
    
    def report
      report = "Aspace Import Report\n"
      report << "DRY RUN MODE\n" if @dry

      unless self.error_log.empty?
        report += self.error_log.map { |e| e.to_s }.join('\n\n')
      end
      
      report
    end
      

    # Errors arising from bad data should be reported
    # out to the user. Other errors can surface 
    # as they arise.
    def run_safe(&block)      
      
      @block = block
            
      begin
        self.run
      rescue JSONModel::ValidationException => e
        @import_summary = "Failed to POST import due to validation error."
        error = LoggableError.new
        error.header = e.class.name
        if e.invalid_object
          if e.invalid_object.respond_to?('title') && !e.invalid_object.title.nil?
            error.record_info[:title] = e.invalid_object.title
          else
            error.record_info[:title] = "Unknown (#{e.invalid_object.to_s})"
          end
          error.record_info[:type] = e.invalid_object.jsonmodel_type.capitalize
        end
        error.messages = e.errors.map {|k,v| "#{k}: #{v}"}
        @error_log << error
      end
    end

    private
    
    
    def emit_status(hsh)
      send_to_client({'status' => [hsh]})
    end
    
    # ParseQueue helpers
    
    # Empty out the parse queue and set any defaults
    def clear_parse_queue
      while !parse_queue.empty?
        parse_queue.pop
      end
    end
  end
  
  
  class LoggableError
    attr_accessor :header
    attr_accessor :record_info
    attr_accessor :messages
    
    def initialize
      @header
      @record_info = {:type => "unknown", :title => "unknown"}
      @messages = []
    end
    
    def to_s
      
      s = "#{@header}\n"
      s << "Record type: #{@record_info[:type].capitalize} \n"
      s << "Record title: #{@record_info[:title].capitalize} \n"
      s << "Error messages: "
      s << @messages.join(' : ')
      s
    end
    
    def to_hash
      self.instance_values
    end
      
  end
  
end

