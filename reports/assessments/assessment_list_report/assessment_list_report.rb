class AssessmentListReport < AbstractReport

  BOOLEAN_FIELDS = ['accession_report', 'appraisal', 'container_list', 'catalog_record',
                    'control_file', 'deed_of_gift', 'finding_aid_ead', 'finding_aid_online',
                    'finding_aid_paper', 'finding_aid_word', 'finding_aid_spreadsheet',
                    'related_eac_records']

  register_report({
                    :params => [["from", Date, "The start of report range"],
                                ["to", Date, "The start of report range"]]
                  })

  def initialize(params, job, db)
    super
    from = params["from"].to_s.empty? ? Time.at(0).to_s : params["from"]
    to = params["to"].to_s.empty? ? Time.parse('9999-01-01').to_s : params["to"]

    @from = DateTime.parse(from).to_time.strftime("%Y-%m-%d %H:%M:%S")
    @to = DateTime.parse(to).to_time.strftime("%Y-%m-%d %H:%M:%S")
  end

  def template
    "assessment_list_report.erb"
  end

  def query
    RequestContext.open(:repo_id => repo_id) do
      Assessment.this_repo
        .filter(:survey_begin => (@from..@to))
        .filter(Sequel.~(:inactive => 1))
        .order(Sequel.asc(:id))
    end
  end

  BATCH_SIZE = 5

  def each_assessment
    RequestContext.open(:repo_id => repo_id) do
      query.each_slice(BATCH_SIZE).each do |objs|
        URIResolver.resolve_references(Assessment.sequel_to_jsonmodel(objs),
                                       ['records', 'surveyed_by', 'reviewer'])
          .each do |assessment_json|
          yield assessment_json
        end
      end
    end
  end

  def normalize_label(s)
    s.strip
  end

  def as_table
    table = AssessmentTable.new

    each_assessment do |assessment|
      row = table.new_row

      row.add_value('basic', 'assessment_id', assessment['display_string'])

      assessment['records'].each do |linked_record|
        parsed_uri = JSONModel.parse_reference(linked_record['ref'])
        row.add_multi_value('basic', 'record', [parsed_uri[:type], parsed_uri[:id]].join('_'))

        resolved = linked_record['_resolved']
        row.add_multi_value('basic', 'linked_record_titles', (resolved['display_string'] || resolved['title']))

        row.add_multi_value('basic', 'linked_record_identifiers',
                            ['id_0', 'id_1', 'id_2', 'id_3', 'component_id', 'digital_object_id'].map {|property|
                              resolved[property]
                            }.compact.join('.'))
      end

      BOOLEAN_FIELDS.each do |field|
        row.add_value('basic', field, !!assessment[field])
      end

      row.add_value('basic', 'existing_description_notes', assessment['existing_description_notes'])

      assessment['surveyed_by'].each do |agent|
        row.add_multi_value('basic', 'surveyed_by', agent['_resolved']['is_user'])
      end

      row.add_value('basic', 'survey_begin', assessment['survey_begin'])
      row.add_value('basic', 'survey_end', assessment['survey_end'])
      row.add_value('basic', 'surveyed_duration', assessment['surveyed_duration'])
      row.add_value('basic', 'surveyed_extent', assessment['surveyed_extent'])
      row.add_value('basic', 'review_required', assessment['review_required'])

      assessment['reviewer'].each do |agent|
        row.add_multi_value('basic', 'reviewer', agent['_resolved']['is_user'])
      end

      row.add_value('basic', 'review_note', assessment['review_note'])
      row.add_value('basic', 'purpose', assessment['purpose'])
      row.add_value('basic', 'scope', assessment['scope'])

      row.add_value('basic', 'monetary_value', assessment['monetary_value'])
      row.add_value('basic', 'monetary_value_note', assessment['monetary_value_note'])

      row.add_value('basic', 'inactive', !!assessment['inactive'])

      row.add_value('basic', 'sensitive_material', assessment['sensitive_material'])
      row.add_value('basic', 'general_assessment_note', assessment['general_assessment_note'])
      row.add_value('basic', 'exhibition_value_note', assessment['exhibition_value_note'])
      row.add_value('basic', 'conservation_note', assessment['conservation_note'])
      row.add_value('basic', 'special_format_note', assessment['special_format_note'])

      Array(assessment['ratings']).each do |rating|
        key = normalize_label(rating['label'])
        row.add_value('rating', key, rating['value'])

        unless rating['readonly']
          # Read-only ratings don't get notes!
          row.add_value('rating', "#{key}_note", rating['note'])
        end
      end

      Array(assessment['formats']).each do |format|
        key = normalize_label(format['label'])
        row.add_value('format', key, !!format['value'])
      end

      Array(assessment['conservation_issues']).each do |conservation_issue|
        key = normalize_label(conservation_issue['label'])
        row.add_value('conservation', key, !!(conservation_issue['value'] == 'true'))
      end
    end

    table
  end

  def to_json
    ASUtils.to_json(as_table.map {|row| row.to_hash})
  end

  def to_csv
    table = as_table

    headers = []

    # Some fields will appear more than once where they can be multi-valued
    # (like "surveyed_by").  Whichever row has the most of a given field will
    # define how many columns we produce.
    table.all_fields.each do |field|
      field_repetitions = table.map {|row| row.field_count(field[:category], field[:field_name])}.max
      headers.concat(field_repetitions.times.map {|idx| field.merge(:idx => idx)})
    end

    CSV.generate do |csv|
      # Put out the double header row
      csv << headers.map {|field| field[:category]}
      csv << headers.map {|field| field[:field_name]}

      table.each do |row|
        csv << headers.map {|header| value_for_csv(row.get_value(header[:category], header[:field_name], header[:idx]))}
      end
    end
  end

  def value_for_csv(value)
    if value === true
      'Y'
    elsif value === false
      'N'
    else
      value
    end
  end


  class AssessmentTable

    include Enumerable

    def initialize
      @rows = []
    end

    def new_row
      row = AssessmentRow.new
      @rows << row
      row
    end

    def all_fields
      fields = @rows.map {|row| row.fields}.flatten(1).uniq

      # We want to produce the fields in the approximate order they were added.
      fields.sort_by {|field| @rows.map {|row| row.fields.index(field)}.compact.min}
    end

    def each
      unless block_given?
        return @rows.each
      end

      @rows.each do |row|
        yield row
      end
    end
  end

  class AssessmentRow
    attr_reader :fields

    def initialize
      @fields = []
      @values = {}
    end

    def get_value(category, field_name, occurrence)
      values = @values.fetch(category, {}).fetch(field_name, nil)

      return nil if values.nil?

      if values.is_a?(Array)
        values.fetch(occurrence, nil)
      else
        raise "BUG: Occurrence can't be > 0 on a non-array" if occurrence > 0
        values
      end
    end

    def field_count(category, field_name)
      @fields.select {|field| field[:category] == category && field[:field_name] == field_name}.count
    end

    def add_value(category, field_name, value)
      @fields << {:category => category, :field_name => field_name}

      return if value.nil?

      @values[category] ||= {}
      @values[category][field_name] = value
    end

    def add_multi_value(category, field_name, value)
      @fields << {:category => category, :field_name => field_name}

      return if value.nil?

      @values[category] ||= {}
      @values[category][field_name] ||= []
      @values[category][field_name] << value
    end

    def to_hash
      @values
    end
  end
end
