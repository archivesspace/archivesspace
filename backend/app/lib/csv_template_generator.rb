require 'csv'
require 'enumerator'

module CsvTemplateGenerator
  class Template

    # A template for users to fill out and upload, to make changes to system data.
    #
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

  # Not yet working, probably need to rewrite code above to return enumerator
  class << self
    def q(*args)
      Sequel.qualify(*args)
    end

    def csv_for_top_container_generation(resource_id)
      tmpl = Template.new(archival_object_id: "Archival Object ID", ref_id: "Ref ID", component_id: "Component ID", resource_title: "Resource Title", identifier: {title: "Identifier", formatter: ->(value) { JSON.parse(value).compact.join(" ") }})
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
