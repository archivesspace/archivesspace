require 'csv'
require_relative 'utils'
require_relative 'record_proxy'

module ASpaceImport
  module CSVConvert

    module ClassMethods
      def configuration
        @configuration ||= self.configure
      end


      def repeatable_record(record_type, options = {})
        repeatable_record_definitions[record_type.to_s] = {
          :record_type => record_type,
        }.merge(options)
      end


      def repeatable_record_definitions
        @repeatable_record_definitions ||= {}
      end


      def repeatable_record_header(header)
        repeatable_record_definitions.each do |namespace, definition|
          match = header.match(/\A#{Regexp.escape(namespace)}_(\d+)_(.+)\z/)
          next unless match
          next unless repeatable_record_fields(definition).include?(match[2])

          return definition.merge(
            :namespace => namespace,
            :index => match[1],
            :property => match[2],
          )
        end

        nil
      end


      def repeatable_record_definition_for_key(key)
        repeatable_record_definitions.each do |namespace, definition|
          match = key.to_s.match(/\A#{Regexp.escape(namespace)}_(\d+)\z/)
          next unless match

          return definition.merge(
            :namespace => namespace,
            :index => match[1].to_i,
          )
        end

        nil
      end


      def configure_cell_handlers(row)
        headers = row.map {|s| s ||= ""; s.strip}.reject {|s| s.empty? }
        c = configuration
        bad_headers = []
        headers.each {|h| bad_headers << h unless h.match /^[a-z]*_[a-z0-9_]*$/ }

        if !bad_headers.empty?
          raise CSVSyntaxException.new(:bad_headers, bad_headers)
        end

        headers.each do |header|
          bad_headers << header unless c.has_key?(header) || repeatable_record_header(header)
        end

        if !bad_headers.empty?
          # raise CSVSyntaxException.new(:unconfigured_headers, bad_headers)
        end

        cell_handlers = headers.map do |header|
          if c.has_key?(header)
            CellHandler.new(*[*c[header], header].reverse)
          elsif (repeatable = repeatable_record_header(header))
            next if repeatable[:parse] == false

            target = "#{repeatable[:namespace]}_#{repeatable[:index]}.#{repeatable[:property]}"
            CellHandler.new(header, target)
          end
        end

        [cell_handlers, bad_headers]
      end


      private

      def repeatable_record_fields(definition)
        return definition[:fields] if definition[:fields]

        ASpaceImport::JSONModel(definition[:record_type]).schema['properties'].reject do |property, property_definition|
          property_definition['readonly'] || ['jsonmodel_type', 'lock_version'].include?(property)
        end.keys
      end
    end


    def self.included(base)
      base.extend(ClassMethods)
    end


    def configuration
      self.class.configuration
    end


    def run
      @cell_handlers = []
      @proxies = ASpaceImport::RecordProxyMgr.new

      CSV.open(@input_file, 'r:bom|utf-8') do |csv|
        csv.each do |row|
          # Entirely blank rows can be safely ignored
          next if row.all? {|cell| cell.to_s.strip.empty? }

          if @cell_handlers.empty?
            @headers = row.map {|s| s ||= ""; s.strip }
            @cell_handlers, bad_headers = self.class.configure_cell_handlers(row)
            unless bad_headers.empty?
              Log.warn("Data source has headers that aren't defined: #{bad_headers.join(', ')}")
              raise CSVSyntaxException.new(:unconfigured_headers, bad_headers)
            end
          else
            parse_row(row)
          end
        end
      end

      @proxies.undischarged.each do |prox|
        Log.warn("Undischarged: #{prox.to_s}")
      end
    end


    def parse_row(row)
      row.each_with_index { |cell, i| parse_cell(@cell_handlers[i], cell) }

      # swap out proxy objects for real JSONModel objects
      @batch.working_area.map! {|proxy| proxy.spawn }.compact!

      sort_repeatable_records!

      # run linking jobs and set defaults
      @batch.working_area.each { |obj| @proxies.discharge_proxy(obj.key, obj) }

      # let subclasses post-process the row's objects before they're flushed
      after_row_parsed(row)

      # empty the working area of the cache
      @batch.flush
    end


    # Hook for subclasses: runs after a row's objects have been parsed and before flush.
    def after_row_parsed(row)
    end


    def repeatable_row_data(namespace, row)
      data = {}

      @headers.each_with_index do |header, index|
        repeatable = self.class.repeatable_record_header(header)
        next unless repeatable && repeatable[:namespace] == namespace

        data[repeatable[:index].to_i] ||= {}
        data[repeatable[:index].to_i][repeatable[:property]] = row[index]
      end

      data.sort_by {|index, _properties| index }
    end


    def normalize_schema_value(record_type, property, raw_value)
      return nil if raw_value.nil? || raw_value == 'NULL' || raw_value.to_s.strip.empty?

      property_definition = ASpaceImport::JSONModel(record_type).schema['properties'].fetch(property)
      property_type = ASpaceImport::Utils.get_property_type(property_definition)[0]

      ASpaceImport::Utils.value_filter(property_type).call(raw_value)
    end


    def parse_cell(handler, cell_contents)
      return nil unless handler

      val = handler.extract_value(cell_contents)

      return nil unless val
      return nil if self.class.repeatable_record_definition_for_key(handler.target_key) && val.to_s.strip.empty?

      get_queued_or_new(handler.target_key) do |prox|
        property = handler.target_path
        prox.set(property, val)
      end
    end


    def get_queued_or_new(key)
      if (prox = @batch.working_area.find {|j| j.key == key })
        yield  prox
      elsif (prox = get_new(key))
        yield prox
        @batch << prox
      end
    end


    def get_new(key)
      repeatable = self.class.repeatable_record_definition_for_key(key)
      configuration_key = repeatable ? repeatable[:namespace].to_sym : key.to_sym
      conf = configuration[configuration_key] || {}

      type = if conf[:record_type]
               conf[:record_type]
             elsif repeatable
               repeatable[:record_type]
             else
               key
             end

      proxy = @proxies.get_proxy_for(key, type)

      if conf[:on_create]
        proxy.on_spawn(conf[:on_create])
      end

      # Set defaults when done getting data
      if conf[:defaults]
        conf[:defaults].each do |key, val|
          proxy.on_discharge(self, :set_default, key, val)
        end
      end

      # Set links before batching the record
      if conf[:on_row_complete]
        proxy.on_discharge(conf[:on_row_complete], :call, @batch.working_area)
      end

      proxy
    end


    private

    def sort_repeatable_records!
      self.class.repeatable_record_definitions.each_key do |namespace|
        positions = []

        @batch.working_area.each_with_index do |obj, position|
          positions << position if repeatable_record_index(obj, namespace)
        end

        sorted = positions.map {|position| @batch.working_area[position] }.sort_by do |obj|
          repeatable_record_index(obj, namespace)
        end

        positions.each_with_index do |position, index|
          @batch.working_area[position] = sorted[index]
        end
      end
    end


    def repeatable_record_index(obj, namespace)
      definition = self.class.repeatable_record_definition_for_key(obj.key)
      definition[:index] if definition && definition[:namespace] == namespace
    end


    def set_default(property, val, obj)
      if obj.send("#{property}").nil?
        obj.send("#{property}=", val)
      end
    end


    class CellHandler
      attr_reader :name
      attr_reader :target_key
      attr_reader :target_path

      def initialize(name, data_path, val_filter = nil)
        @name = name
        @target_key, @target_path = data_path.split(".")
        @val_filter = val_filter
      end


      def extract_value(cell_contents)
        return nil if cell_contents.nil? || cell_contents == 'NULL'
        @val_filter ? @val_filter.call(cell_contents) : cell_contents
      end
    end


    class CSVSyntaxException < StandardError

      def initialize(type, element)
        @type = type
        @element = element
      end

      def to_s
        columns = Array(@element).join(', ')

        case @type
        when :unconfigured_headers
          "Unrecognized CSV headers: #{columns}"
        when :bad_headers
          "Invalid CSV headers: #{columns}"
        else
          "#<:CSVSyntaxException: #{@type} => #{@element.inspect}"
        end
      end
    end

  end
end
