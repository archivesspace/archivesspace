require 'csv'
require 'enumerator'

module CsvTemplateGenerator

  class CsvTemplateError < StandardError
    # pass
  end

  class TemplateSpec

    attr_accessor :sheet_description, # Description of spreadsheet as a whole

                  # The various *_text fields are put into the first column of the spreadsheet and describe rows
                  :group_text,        # groupings of fields, e.g. "Resource Fields", optional
                  :description_text,  # longform description of field, optional
                  :field_name_text,   # The machine-readable name of the field, used as a key in column definitions, required
                  :title_text,        # human readable titles, required

                  :columns            # a hash of hashes, keys are field_names, values are hashes describing columns


    # The :columns key in TemplateSpec should be a Hash of Hashes, with entries representing columns.
    # Each key is a `field_name`, and should match a key in the expected dataset (i.e. a column name/alias in SQL)
    #   unless the column_spec has :blank => true. This key is the machine-readable name of a column.

    # Each value is a `column_spec`.
    # A column_spec is either a string, or a hash with keys from the set {:title, :description, :group, :blank, :formatter},
    #   :title, is required, other keys are optional.

    # Allowed keys in column_spec:
    #   :title is a human-readable name for the column
    #   :description is a longer narrative description of the column. If any column has a :description, all columns MUST.
    #     Otherwise, the line will be omitted.
    #   :group is an arbitrary string used to group columns. If any column has a :group, all columns MUST. Otherwise, the line will be omitted.
    #   :blank means that the value should be left empty for the user to fill in
    #   :required means the value is required, ' (required)' will be added to the column title
    # :formatter is a callable that will be applied to the returned values from the database

    def initialize(sheet_description:, field_name_text:, title_text:, columns:, # required fields
                   group_text: false, description_text: false)                # optional fields
      @sheet_description = sheet_description
      @field_name_text = field_name_text
      @title_text = title_text
      @columns = columns


      @group_text = group_text
      @description_text = description_text

      errors = []

      unless !!@group_text == @columns.values.all? {|col| Hash === col && col[:group] }
        errors << ":group_text value: #{group_text} and column values for :group do not agree, either add :group_text value or remove :group from columns as needed."
      end

      unless !!@description_text == columns.values.all? {|col| col.kind_of?(Hash) && col[:description] }
        errors << ":description_text value: #{description_text} and column values for :description do not agree, either add :description_text value or remove :description from columns as needed."
      end

      if errors.count > 0
        raise CsvTemplateError, errors.join(" ")
      end
    end
  end

  class Template
    # A template for users to fill out and upload, to make bulk changes to system data.

    # For examples of usage, look at the module-level methods in this very file!
    def initialize(template_spec, csv_options = {})
      @template_spec = template_spec
      @fields = @template_spec.columns.keys

      @headers = [[@template_spec.sheet_description] + ([""] * (@template_spec.columns.count - 1))]

      @headers << [@template_spec.group_text] + @fields.map {|k| get_group(k) } if @template_spec.group_text
      @headers << [@template_spec.description_text] + @fields.map {|k| get_desc(k) } if @template_spec.description_text

      @headers += ([[@template_spec.field_name_text, @template_spec.title_text]] + @fields.map {|k| [k.to_s, get_title(k).to_s]}).transpose
      @csv_options = {encoding: 'UTF-8'}.merge(csv_options)
    end

    def get_title(field)
      spec = @template_spec.columns[field]
      case spec
      when Hash
        spec[:title] + spec[:required] ? ' (required)' : ''
      else
        spec + spec[:required] ? ' (required)' : ''
      end
    end

    def get_desc(field)
      spec = @template_spec.columns[field]
      case spec
      when Hash
        spec[:description]
      else
        nil
      end
    end

    def get_group(field)
      spec = @template_spec.columns[field]
      case spec
      when Hash
        spec[:group]
      else
        nil
      end
    end

    def get_format(field)
      spec = @template_spec.columns[field]
      if Hash === spec
        spec[:formatter]
      else
        nil
      end
    end

    def is_blank?(field)
      spec = @template_spec.columns[field]
      Hash === spec && spec[:blank]
    end

    def is_required?(field)
      spec = @template_spec.columns[field]
      Hash === spec && spec[:required]
    end

    def formatted_value(field, value)
      return nil if is_blank? field

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
          y.yield CSV.generate_line([''] + @fields.map do |field| formatted_value(field, row[field]) end, **@csv_options)
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
        TemplateSpec.new(
          sheet_description: "Archival Object Top Container Generation Template",
          field_name_text: "ArchivesSpace field code (please don't edit this row)",
          title_text: "Field Name",
          group_text: "Maps to ASpace Type",
          description_text: "Description of Field",
          columns: {
            # For reference
            archival_object_id: {title: "Archival Object ID", group: "Archival Object", description: "Archival Object Database ID"},
            ref_id: {title: "Ref ID", group: "Archival Object", description: "Reference ID for AO" },
            component_id: {title: "Component ID", group: "Archival Object", description: "foo"},
            resource_title: {title: "Resource Title", group: "Resource", description: "foo"},
            ead_id: {title: "EAD ID", group: "Resource" , description: "foo"},
            identifier: {title: "Identifier", group: "Resource", formatter: ->(value) { JSON.parse(value).compact.join(" ") }, description: "foo"},
            # Editable
            instance_type: {title: "Instance Type", group: "Container", blank: true, description: "foo"},
            top_container_id: {title: "Top Container ID (existing top container, leave blank if creating new container)", group: "Container", blank: true, description: "foo"},
            top_container_type: {title: "Top Container Type", blank: true, group: "Container", description: "foo"},
            top_container_indicator: {title: "Top Container Indicator", group: "Container", blank: true, description: "foo"},
            top_container_barcode: {title: "Top container barcode", group: "Container", blank: true, description: "foo"},
            container_profile_id: {title: "Container Profile ID", group: "Container", blank: true, description: "foo"},
            child_type: {title: "Child Type", group: "Container", blank: true, description: "foo"},
            child_indicator: {title: "Child Indicator", group: "Container", blank: true, description: "foo"},
            child_barcode: {title: "Child Barcode", group: "Container", blank: true, description: "foo"},
            location_id: {title: "Location ID", group: "Location", blank: true, description: "foo"}
          }
        )
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
            q(:resource, :ead_id),
            q(:resource, :identifier)
          ).
          order(q(:archival_object, :id))
      end
      tmpl.each(dataset)
    end
  end
end
