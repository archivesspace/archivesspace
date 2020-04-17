require 'csv'
require 'enumerator'

module CsvTemplateGenerator
  class Template

    # A template for users to fill out and upload, to make bulk changes to system data.

    # A template_spec takes the form of a hash of the form: key => column_spec.

    # The key to a column should match a key in the expected dataset (i.e. a column name/alias in SQL)
    # unless the column_spec has :blank => true

    # Each column_spec is either a string, or a hash with keys from the set {:title, :blank, :formatter},
    # :title is required, other keys are optional.

    # :title is a human-readable description of the column

    # :blank means that the value should be left empty for the user to fill in

    # :formatter is a callable that will be applied to the returned values from the database

    # For examples of usage, look at the module-level methods in this very file!
    def initialize(template_spec, csv_options = {})
      @template_spec = template_spec
      @headers = @template_spec.keys.map {|k| [k.to_s, get_title(k).to_s]}.transpose

      @csv_options = {encoding: 'UTF-8'}.merge(csv_options)
    end

    def get_title(field)
      spec = @template_spec[field]
      case spec
      when Hash
        spec[:title]
      else
        spec
      end
    end

    def get_format(field)
      spec = @template_spec[field]
      if Hash === spec
        spec[:formatter]
      else
        nil
      end
    end

    def is_blank?(field)
      spec = @template_spec[field]
      Hash === spec && spec[:blank]
    end

    def formatted_value(field, value)
      return '' if is_blank? field

      formatter = get_format(field)
      if formatter
        formatter.call(value)
      else
        value
      end
    end

    # creates an enumerator over a dataset, which returns successive lines of CSV
    # if a block is provided, iterates over the enumerator
    def each(dataset)
      enum = Enumerator.new do |y|
        @headers.each do |hdr_line|
          y.yield CSV.generate_line(hdr_line, **@csv_options)
        end
        dataset.paged_each do |row|
          y.yield CSV.generate_line(@template_spec.keys.map do |field| formatted_value(field, row[field]) end, **@csv_options)
        end
      end
      if not block_given?
        return enum
      else
        enum.each do |el|
          yield el
        end
      end
    end
  end


  class << self

    def q(*args)
      # Convenience method to get qualified names without having to type 14 chars
      Sequel.qualify(*args)
    end

    # Module-level methods here are primarily what's called by consumers
    # at the controller level.  Generally they will consist of
    #   1. instantiate a template definition
    #   2. fetch a a dataset
    #   3. return an enumerator over CSV lines for streaming to frontend/direct download
    def csv_for_top_container_generation(resource_id)
      tmpl = Template.new(
        # For reference
        archival_object_id: "Archival Object ID",
        ref_id: "Ref ID",
        component_id: "Component ID",
        resource_title: "Resource Title",
        identifier: {title: "Identifier", formatter: ->(value) { JSON.parse(value).compact.join(" ") }},
        # Editable
        instance_type: {title: "Instance Type", blank: true},
        top_container_type: {title: "Top Container Type", blank: true},
        top_container_indicator: {title: "Top Container Indicator", blank: true},
        top_container_barcode: {title: "Top container barcode", blank: true},
        child_type: {title: "Child Type", blank: true},
        child_indicator: {title: "Child Indicator", blank: true},
        child_barcode: {title: "Child Barcode", blank: true},
        location_id: {title: "Location ID", blank: true}
      )

      dataset = DB.open do |ds|
        ds[:resource].
          inner_join(:archival_object, :root_record_id => :id).
          where(q(:resource, :id)  => resource_id).
          select(
            q(:archival_object, :id).as(:archival_object_id),
            q(:archival_object, :ref_id),
            q(:archival_object, :component_id),
            q(:resource, :title).as(:resource_title),
            q(:resource, :identifier)
          ).
          order(q(:archival_object, :id))
      end
      tmpl.each(dataset)
    end
  end
end
