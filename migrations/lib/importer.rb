module ASpaceImport
  
  def self.init
    Dir.glob(File.dirname(__FILE__) + '/../importers/*', &method(:load))
  end
  
  
  class Importer

    @@importers = {}
    attr_accessor :parse_queue

    def self.list
      list = "The following importers are available"
      @@importers.each do |i, klass|
        list += "\t #{klass.name} \t #{klass.profile}"
      end
      list
    end

    # @param options [Hash] runtime options passed into the importer
    # @return [Object] an instance of the selected importer
    # @raise [StandardError] if the class of the selected importer doesn't pass the usability test

    def self.create_importer(opts)
      i = @@importers[opts[:importer].to_sym]
      if i.usable
        if opts[:crosswalk]
          ASpaceImport::Crosswalk.init(opts)
        end
        i.new opts
      else
        raise StandardError.new("Unusable importer or importer not found for: #{name}")
      end
    end
    
    def self.destroy_importers
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
        Object.const_set("#{name.to_s.capitalize}Importer", c)
        @@importers[name] = c
        true
      end
    end

    def self.usable
      true
    end

    def initialize(opts = { })
      
      raise "Need a repo_id in order to run" unless opts[:repo_id]
      
      JSONModel::set_repository(opts[:repo_id])
      
      opts.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
      @import_keys = []
      @goodimports = 0
      @import_log = []
      @uri_map = {}

      @parse_queue = ASpaceImport::ParseQueue.new(opts)
    end

    def log_save_result(response)
      @import_log << response
      if !@dry && response.code == '200'
        @uri_map = JSON.parse(response.body)['saved']
      end
    end
    
    def save_all
      log_save_result(@parse_queue.save)
    end
    
    def report_summary
      return "Nothing Logged" if @import_log.empty?
      if @dry
        "DRY RUN -- Records Saved: #{JSON.parse(@import_log[0])['saved'].length}"
      else
        @import_log.map { |r| 
          "#{r.code} -- Records Saved: #{r.code == '200' ? JSON.parse(r.body)['saved'].length : 'Error' }" 
        }.join('\n')
      end
    end
    
    def report
      if @dry
        report_summary
      else
        report = "Aspace Import Report\n"
        report += "--Executive Summary--\n"
        report += report_summary
        report += "\n--Details--\n"
        report += @import_log.map { |r| 
          "#{r.code}\n" + (r.code == '200'  ? JSON.parse(r.body)['saved'].map{ |k,u| "Saved: #{u}" }.join("\n") : JSON.parse(r.body).to_s)
        }.join('\n')
      
        report
      end
    end
    
    def import_log
      @import_log
    end
    
    def uri_map
      @uri_map
    end

    def run
      raise StandardError.new("Unexpected error: run method must be defined by a subclass")
    end
    
    # ParseQueue helpers
    
    # Empty out the parse queue and set any defaults
    def clear_parse_queue
      while !@parse_queue.empty?
        puts @parse_queue.last.inspect
        @parse_queue.last.receivers.each { |r| r.receive }
        @parse_queue.pop
      end
    end
  end
end

