require_relative 'utils'
require_relative 'record_proxy'

module ASpaceImport
  module CSVImport
    
    module ClassMethods
      def configuration
        @configuration ||= self.configure
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
      
    def configuration
      self.class.configuration
    end
    
    
    def run
      
      # i = 0
      @headers = []
    
      CSV.foreach(@input_file) do |row|
    
        # i = i+1
    
        if @headers.empty?
          @headers = row
          bad_headers = []
          @headers.each {|h| bad_headers << h unless h.match /^[a-z]*_[a-z0-9_]*$/ }
          if !bad_headers.empty?
            raise CSVSyntaxException.new(:bad_headers, bad_headers)
          end
        else
          parse_row(row) #unless i > 2
        end
      end
    
    
      save_all
      
      ASpaceImport::RecordProxy.undischarged.each do |prox|
        @log.warn("Undischarged: #{prox.to_s}")
      end
    
    end
    
    
    def parse_row(row)

      row.each_with_index do |cell, i|
        parse_cell(@headers[i], cell)
      end

      parse_queue.each do |obj|   
        ASpaceImport::RecordProxy.discharge_proxy(obj.key, obj)
      end
      
      @log.debug(parse_queue.inspect)
      
      clear_parse_queue
    end
    
    
    def parse_cell(header, val)

      val = nil if val == 'NULL'
      
      return nil if val.nil?

      @log.debug("PARSING HEADER: #{header} VALUE: #{val}")

      if configuration.has_key?(header)

        # TODO - optimize out?
        # TODO - check the config ahead of time
        if configuration[header].is_a?(Array)
          path_string = configuration[header][1]
          val = configuration[header][0].call(val)
        else
          path_string = configuration[header]
        end
          
        path = path_string.scan(/[^.]+/)

        obj = get_queued_or_new(path.slice!(0))

        # TODO - combine these in utils
        property_type = ASpaceImport::Utils.get_property_type(obj.class.schema['properties'][path.last])
        filtered_val = ASpaceImport::Utils.value_filter(property_type[0]).call(val)

        obj.send("#{path.last}=", filtered_val)

      else
        @log.warn("Unconfigured CSV header: #{header}") 
      end
    end
    
    # TODO - optimize by running this logic one per key
    
    def get_new(key)

      conf = configuration[key.to_sym]
      
      if conf.nil?
        conf = {}
      end

      if conf[:record_type]
        type = conf[:record_type]
      else
        type = key
      end

      obj = ASpaceImport::JSONModel(type).new
      obj.key = key
        
      if conf[:path] || conf[:defaults]
        proxy = ASpaceImport::RecordProxy.get_proxy_for(key)
              
        # Set defaults when done getting data
        if conf[:defaults]
          conf[:defaults].each do |key, val|
            proxy.on_discharge(self, :set_default, key, val)
          end
        end
        
        # Set path when complete
        if conf[:path]  
          path = conf[:path].scan(/[^.]+/)
          set_property ancestor(path[0]), path[1], proxy
        end
        
        # Do what needs to be done before batching the record
        if conf[:on_row_complete]
          proxy.on_discharge(conf[:on_row_complete], :call, parse_queue)
        end
        
      end
          
      @parse_queue.push(obj)
    
      obj
    end

    def get_queued_or_new(key)
      if (obj = @parse_queue.find {|j| j.key == key })  
        obj
      else
        get_new(key)
      end
    end


    def set_default(property, val, obj)
      if obj.send("#{property}").nil?       
        obj.send("#{property}=", val)
      end
    end
    
   
    def ancestor(*types)
      obj = parse_queue.reverse.find { |o| types.map {|t| t.to_s }.include?(o.class.record_type)}
      obj
    end
        
    
    def set_property(obj = :context, property, value)

      if obj.nil?
        raise "Trying to set property #{property} on nil object"
      end

      if property.nil?
        @log.warn("Can't set <#{obj.class.record_type}> <#{property}>: nil value")
        return false
      end

      obj = context_obj if obj == :context

      @log.debug("Setting <#{obj.jsonmodel_type}> <#{property}> using <#{value.inspect}> (unfiltered)")

      begin
        property_type = ASpaceImport::Utils.get_property_type(obj.class.schema['properties'][property.to_s])
      rescue NoMethodError
        raise "Having some trouble finding a property <#{property}> on a <#{obj.class.record_type}> object"
      end

      if value.is_a?(ASpaceImport::RecordProxy)
        value.on_discharge(self, :set_property, obj, property)
      else
        if value.nil?
          @log.warn("Given a nil value for <#{obj.class.record_type}><#{property}>")
        else
          filtered_value = ASpaceImport::Utils.value_filter(property_type[0]).call(value)
          @log.debug("Filtered Value: #{filtered_value.inspect}")
          if property_type[0].match /list$/
            val_array = obj.send("#{property}").push(filtered_value)
            obj.send("#{property}=", val_array)
          else
            if obj.send("#{property}")
              @log.warn("Setting a property that has already been set")
            end
            obj.send("#{property}=", filtered_value)
          end
        end
      end

    end
        
        
    class CSVSyntaxException < StandardError

      def initialize(type, element)
        @type = type
        @element = element
      end

      def to_s
        "#<:CSVSyntaxException: #{@type} => #{@element.inspect}"
      end
    end    

  end
end
    
    
    