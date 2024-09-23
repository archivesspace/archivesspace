require 'date'
require 'time'
require 'barcode_check'

module JSONModel::Validations
  extend JSONModel


  def self.check_identifier(hash)
    ids = (0...4).map {|i| hash["id_#{i}"]}

    errors = []

    if ids.reverse.drop_while {|elt| elt.to_s.empty?}.any? {|elt| elt.to_s.empty?}
      errors << ["identifier", "must not contain blank entries"]
    end

    errors
  end


  [:archival_object, :accession, :resource].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("#{type}_check_identifier") do |hash|
        check_identifier(hash)
      end
    end
  end

  # ANW-1232: add validations to prevent software agents from having/saving record control or agent relation subrecords.
  # These records are hidden from the forms but allowed through the schema (as agent_software inherits from abstract_agent) so these validations serve to prevent these subrecords from being added via API calls.
  if JSONModel(:agent_software)
    JSONModel(:agent_software).add_validation("check_agent_software_subrecords") do |hash|
      check_agent_software_subrecords(hash)
    end

  end

  [:agent_function, :agent_place, :agent_occupation, :agent_topic].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("check_#{type}_subject_subrecord") do |hash|
        check_agent_subject_subrecord(hash)
      end
    end
  end


  [:structured_date_label].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("check_structured_date_label") do |hash|
        check_structured_date_label(hash)
      end
    end
  end

  [:structured_date_single].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("check_structured_date_single") do |hash|
        check_structured_date_single(hash)
      end
    end
  end

  [:structured_date_range].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("check_structured_date_range") do |hash|
        check_structured_date_range(hash)
      end
    end
  end

  [:used_language].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("check_used_language") do |hash|
        check_used_language(hash)
      end
    end
  end


  [:agent_sources].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("check_agent_sources") do |hash|
        check_agent_sources(hash)
      end
    end
  end

  [:agent_alternate_set].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("check_agent_alternate_set") do |hash|
        check_agent_alternate_set(hash)
      end
    end
  end

  # Specification:
  # https://www.pivotaltracker.com/story/show/41430143
  # See also: https://www.pivotaltracker.com/story/show/51373893
  def self.check_source(hash)
    errors = []

    # non-authorized forms don't need source or rules
    return errors if !hash['authorized']

    if hash["source"].nil?
      if hash["rules"].nil?
        errors << ["rules", "is required when 'source' is blank"]
        errors << ["source", "is required when 'rules' is blank"]
      end
    end

    errors
  end

  # https://www.pivotaltracker.com/story/show/51373893
  def self.check_authority_id(hash)
    warnings = []
    if hash["source"].nil? && hash["authority_id"]
      warnings << ["source", "is required if there is an authority id"]
    end

    warnings
  end

  def self.check_name(hash)
    errors = []
    errors << ["sort_name", "Property is required but was missing"] if hash["sort_name"].nil? and !hash["sort_name_auto_generate"]
    errors
  end

  [:name_person, :name_family, :name_corporate_entity, :name_software].each do |type|
    if JSONModel(type)
      # ANW-429: make source and rules completely optional. Is this (check_source) the right validation to change? See:
      # https://docs.google.com/spreadsheets/d/1fL44mUxo8D9o45NHsjKd21ljbvWJzNBQCIm4_Q_tcTU/edit#gid=0
      # ^^ Cell 85
      #JSONModel(type).add_validation("#{type}_check_source") do |hash|
        #check_source(hash)
      #end
      JSONModel(type).add_validation("#{type}_check_name") do |hash|
        check_name(hash)
      end
      JSONModel(type).add_validation("#{type}_check_authority_id", :warning) do |hash|
        check_authority_id(hash)
      end
    end
  end


  # Take a date like YYYY or YYYY-MM and pad to YYYY-MM-DD
  #
  # Note: this might not yield a valid date.  The only goal is that something
  # valid on the way in remains valid on the way out.
  #
  def self.normalise_date(date)
    negated = date.start_with?("-")

    parts = date.gsub(/^-/, '').split(/-/)

    # Pad out to the right length
    padded = (parts + ['01', '01']).take(3)

    (negated ? "-" : "") + padded.join("-")
  end


  # Returns a valid date or throws if the input is invalid.
  def self.parse_sloppy_date(s)
    begin
      Date.strptime(normalise_date(s), '%Y-%m-%d')
    rescue
      raise ArgumentError.new($!)
    end
  end


  def self.check_date(hash)
    errors = []

    begin
      begin_date = parse_sloppy_date(hash['begin']) if hash['begin']
    rescue ArgumentError => e
      errors << ["begin", "not a valid date"]
    end

    begin
      if hash['end']
        # If padding our end date with months/days would cause it to fall before
        # the start date (e.g. if the start date was '2000-05' and the end date
        # just '2000'), use the start date in place of end.
        end_s = if begin_date && hash['begin'] && hash['begin'].start_with?(hash['end'])
                  hash['begin']
                else
                  hash['end']
                end

        end_date = parse_sloppy_date(end_s)
      end
    rescue ArgumentError
      errors << ["end", "not a valid date"]
    end

    if begin_date && end_date && end_date < begin_date
      errors << ["end", "must not be before begin"]
    end

    if hash["expression"].nil? && hash["begin"].nil? && hash["end"].nil?
      errors << ["expression", "is required unless a begin or end date is given"]
      errors << ["begin", "is required unless an expression or an end date is given"]
      errors << ["end", "is required unless an expression or a begin date is given"]
    end

    errors
  end

  def self.check_structured_date_label(hash)
    errors = []

    if !hash["structured_date_range"] && !hash["structured_date_single"]
      errors << ["structured_date_label", "must_specify_either_a_single_or_ranged_date"]
    end

    if hash["structured_date_range"] && hash["structured_date_single"]
      errors << ["structured_date_single", "cannot specify both a single and ranged date"]
    end

    if hash["structured_date_range"] && hash["date_type_structured"] == "single"
      errors << ["structured_date_range", "Must specify single date for date type of single"]
    end

    if hash["structured_date_single"] && hash["date_type_structured"] == "range"
      errors << ["structured_date_range", "Must specify range date for date type of range"]
    end

    return errors
  end

  def self.check_structured_date_single(hash)
    errors = []

    if hash["date_role"].nil?
      errors << ["date_role", "is required"]
    end

    has_expr_date = !hash["date_expression"].nil? &&
                    !hash["date_expression"].empty?

    has_std_date = !hash["date_standardized"].nil?

    errors << ["date_standardized", "or date expression is required"] unless has_expr_date || has_std_date

    if has_std_date
      errors = check_standard_date(hash["date_standardized"], errors)
    end

    return errors
  end

  def self.check_structured_date_range(hash)
    errors = []

    has_begin_expr_date = !hash["begin_date_expression"].nil? &&
                          !hash["begin_date_expression"].empty?

    has_end_expr_date = !hash["end_date_expression"].nil? &&
                        !hash["end_date_expression"].empty?

    has_begin_std_date = !hash["begin_date_standardized"].nil? &&
                         !hash["begin_date_standardized"].empty?

    has_end_std_date =   !hash["end_date_standardized"].nil? &&
                         !hash["end_date_standardized"].empty?

    errors << ["begin_date_expression", "is required"] if !has_begin_expr_date && (!has_begin_std_date && !has_end_std_date)

    errors << ["end_date_expression", "requires begin date expression to be defined"] if !has_begin_expr_date && has_end_expr_date

    errors << ["end_date_standardized", "requires begin_date_standardized to be defined"] if (!has_begin_std_date && has_end_std_date)

    if has_begin_std_date
      errors = check_standard_date(hash["begin_date_standardized"], errors, "begin_date_standardized")
    end

    if has_end_std_date
      errors = check_standard_date(hash["end_date_standardized"], errors, "end_date_standardized")
    end

    if errors.length == 0 && hash["begin_date_standardized"] && hash["end_date_standardized"]
      begin
        if hash["begin_date_standardized"]
          bt = parse_sloppy_date(hash["begin_date_standardized"])
        end

        if hash["end_date_standardized"]
          et = parse_sloppy_date(hash["end_date_standardized"])
        end
      rescue => e
        errors << ["begin_date_standardized", "Error attempting to parsing dates"]
      end

      errors << ["begin_date_standardized", "requires that end dates are after begin dates"] if bt && et && bt > et
    end

    return errors
  end

  def self.check_agent_sources(hash)
    errors = []

    if (hash["source_entry"].nil?     || hash["source_entry"].empty?) &&
       (hash["descriptive_note"].nil? || hash["descriptive_note"].empty?) &&
       (hash["file_uri"].nil?         || hash["file_uri"].empty?)

      errors << ["agent_sources", "Must specify one of Source Entry, Descriptive Note or File URI"]
    end

    return errors
  end

  def self.check_agent_alternate_set(hash)
    errors = []

    if (hash["set_component"].nil?    || hash["set_component"].empty?) &&
       (hash["descriptive_note"].nil? || hash["descriptive_note"].empty?) &&
       (hash["file_uri"].nil?         || hash["file_uri"].empty?)

      errors << ["agent_sources", "Must specify one of Set Component, Descriptive Note or File URI"]
    end

    return errors
  end

  def self.check_agent_subject_subrecord(hash)
    errors = []

    if hash["subjects"].empty?
      errors << ["subjects", "Must specify a primary subject"]
    end

    return errors
  end

  def self.check_agent_software_subrecords(hash)
    errors = []
    subrecords_disallowed = ["agent_record_identifiers", "agent_record_controls", "agent_other_agency_codes", "agent_conventions_declarations", "agent_maintenance_histories", "agent_sources", "agent_alternate_sets", "agent_resources"]

    subrecords_disallowed.each do |sd|
      unless hash[sd] == [] || hash[sd].nil?
        errors << [sd, "subrecord not allowed for agent software"]
      end
    end

    return errors
  end

  def self.check_used_language(hash)
    errors = []

    if hash["language"].nil? && hash["notes"].empty?
      errors << ["language", "Must specify either language or a note."]
    end

    return errors
  end


  if JSONModel(:date)
    JSONModel(:date).add_validation("check_date") do |hash|
      check_date(hash)
    end
  end


  def self.check_language(hash)
    langs = hash['lang_materials'].map {|l| l['language_and_script']}.compact.reject {|e| e == [] }.flatten

    errors = []

    if langs == []
      errors << :must_contain_at_least_one_language
    end

    errors
  end

  if JSONModel(:resource)
    JSONModel(:resource).add_validation("check_language") do |hash|
      check_language(hash)
    end
  end


  def self.check_rights_statement(hash)
    errors = []

    if hash["rights_type"] == "copyright"
      errors << ["status", "missing required property"] if hash["status"].nil?
      errors << ["jurisdiction", "missing required property"] if hash["jurisdiction"].nil?
      errors << ["start_date", "missing required property"] if hash["start_date"].nil?

    elsif hash["rights_type"] == "license"
      errors << ["license_terms", "missing required property"] if hash["license_terms"].nil?
      errors << ["start_date", "missing required property"] if hash["start_date"].nil?

    elsif hash["rights_type"] == "statute"
      errors << ["statute_citation", "missing required property"] if hash["statute_citation"].nil?
      errors << ["jurisdiction", "missing required property"] if hash["jurisdiction"].nil?
      errors << ["start_date", "missing required property"] if hash["start_date"].nil?

    elsif hash["rights_type"] == "other"
      errors << ["other_rights_basis", "missing required property"] if hash["other_rights_basis"].nil?
      errors << ["start_date", "missing required property"] if hash["start_date"].nil?
    end

    errors
  end


  if JSONModel(:rights_statement)
    JSONModel(:rights_statement).add_validation("check_rights_statement") do |hash|
      check_rights_statement(hash)
    end
  end


  def self.check_location(hash)
    errors = []

    # When creating a location, a minimum of one of the following is required:
    #   * Barcode
    #   * Classification
    #   * Coordinate 1 Label AND Coordinate 1 Indicator
    required_location_fields = [["barcode"],
                                ["classification"],
                                ["coordinate_1_indicator", "coordinate_1_label"]]

    if !required_location_fields.any? { |fieldset| fieldset.all? {|field| hash[field]} }
      errors << :location_fields_error
    end

    errors
  end


  if JSONModel(:location)
    JSONModel(:location).add_validation("check_location") do |hash|
      check_location(hash)
    end
  end


  def self.check_container_location(hash)
    errors = []

    errors << ["end_date", "is required if status is previous"] if hash["end_date"].nil? and hash["status"] == "previous"

    errors
  end


  if JSONModel(:container_location)
    JSONModel(:container_location).add_validation("check_container_location") do |hash|
      check_container_location(hash)
    end
  end


  def self.check_instance(hash)
    errors = []

    if hash["instance_type"] == "digital_object"
      errors << ["digital_object", "Can't be empty"] if hash["digital_object"].nil?

    elsif hash["digital_object"] && hash["instance_type"] != "digital_object"
      errors << ["instance_type", "An instance with a digital object reference must be of type 'digital_object'"]

    elsif hash["instance_type"]
      errors << ["sub_container", "Can't be empty"] if hash["sub_container"].nil?
    end

    errors
  end


  if JSONModel(:instance)
    JSONModel(:instance).add_validation("check_instance") do |hash|
      check_instance(hash)
    end
  end

  def self.check_sub_container(hash)
    errors = []

    if (!hash["type_2"].nil? && hash["indicator_2"].nil?) || (hash["type_2"].nil? && !hash["indicator_2"].nil?)
      errors << ["type_2", "container 2 requires both a type and indicator"]
    end

    if (hash["type_2"].nil? && hash["indicator_2"].nil? && (!hash["type_3"].nil? || !hash["indicator_3"].nil?))
      errors << ["type_2", "container 2 is required if container 3 is provided"]
    end

    if (!hash["type_3"].nil? && hash["indicator_3"].nil?) || (hash["type_3"].nil? && !hash["indicator_3"].nil?)
      errors << ["type_3", "container 3 requires both a type and indicator"]
    end

    errors
  end

  if JSONModel(:sub_container)
    JSONModel(:sub_container).add_validation("check_sub_container") do |hash|
      check_sub_container(hash)
    end
  end


  def self.check_container_profile(hash)
    errors = []

    # Ensure depth, width and height have no more than 2 decimal places
    ["depth", "width", "height"].each do |k|
      if hash[k] !~ /^\s*(?=.*[0-9])\d*(?:\.\d{1,2})?\s*$/
        errors << [k, "must be a number with no more than 2 decimal places"]
      end
    end

      # Ensure stacking limit is a positive integer if it has value
    if !hash['stacking_limit'].nil? and hash['stacking_limit'] !~ /^\d+$/
      errors << ['stacking_limit', 'must be a positive integer']
    end

    errors
  end

  if JSONModel(:container_profile)
    JSONModel(:container_profile).add_validation("check_container_profile") do |hash|
      check_container_profile(hash)
    end
  end


  def self.check_collection_management(hash)
    errors = []

    if !hash["processing_total_extent"].nil? and hash["processing_total_extent_type"].nil?
      errors << ["processing_total_extent_type", "is required if total extent is specified"]
    end

    [ "processing_hours_per_foot_estimate", "processing_total_extent", "processing_hours_total" ].each do |k|
      if !hash[k].nil? and hash[k] !~ /^\-?\d{0,9}(\.\d{1,5})?$/
        errors << [k, "must be a number with no more than nine digits and five decimal places"]
      end
    end


    errors
  end


  if JSONModel(:collection_management)
    JSONModel(:collection_management).add_validation("check_collection_management") do |hash|
      check_collection_management(hash)
    end
  end


  def self.check_user_defined(hash)
    errors = []

    ["integer_1", "integer_2", "integer_3"].each do |k|
      if !hash[k].nil? and hash[k] !~ /^\-?\d+$/
        errors << [k, "must be an integer"]
      end
    end

    ["real_1", "real_2", "real_3"].each do |k|
      if !hash[k].nil? and hash[k] !~ /^\-?\d{0,9}(\.\d{1,5})?$/
        errors << [k, "must be a number with no more than nine digits and five decimal places"]
      end
    end

    errors
  end


  if JSONModel(:user_defined)
    JSONModel(:user_defined).add_validation("check_user-defined") do |hash|
      check_user_defined(hash)
    end
  end


  if JSONModel(:resource)
    JSONModel(:resource).add_validation("check_resource_otherlevel") do |hash|
      check_otherlevel(hash)
    end
  end


  def self.check_otherlevel(hash)
    errors = []

    if hash["level"] == "otherlevel"
      errors << ["other_level", "missing required property"] if hash["other_level"].nil?
    end

    errors
  end

  def self.check_archival_object(hash)
    errors = []

    if (!hash.has_key?("dates") || hash["dates"].empty?) && (!hash.has_key?("title") || hash["title"].empty?)
      errors << ["dates", "one or more required (or enter a Title)"]
      errors << ["title", "must not be an empty string (or enter a Date)"]
    end

    errors
  end


  if JSONModel(:archival_object)
    JSONModel(:archival_object).add_validation("check_archival_object") do |hash|
      check_archival_object(hash)
    end

    JSONModel(:archival_object).add_validation("check_archival_object_otherlevel") do |hash|
      check_otherlevel(hash);
    end

  end


  def self.check_digital_object_component(hash)
    errors = []

    fields = ["dates", "title", "label"]

    if fields.all? {|field| !hash.has_key?(field) || hash[field].empty?}
      fields.each do |field|
        errors << [field, "you must provide a label, title or date"]
      end
    end

    errors
  end


  JSONModel(:digital_object_component).add_validation("check_digital_object_component") do |hash|
    check_digital_object_component(hash)
  end


  JSONModel(:event).add_validation("check_event") do |hash|
    errors = []

    if hash.has_key?("date") && hash.has_key?("timestamp")
      errors << ["date", "Can't specify both a date and a timestamp"]
      errors << ["timestamp", "Can't specify both a date and a timestamp"]
    end

    if !hash.has_key?("date") && !hash.has_key?("timestamp")
      errors << ["date", "Must specify either a date or a timestamp"]
      errors << ["timestamp", "Must specify either a date or a timestamp"]
    end

    if hash["timestamp"]
      # Make sure we can parse it
      begin
        Time.parse(hash["timestamp"])
      rescue ArgumentError
        errors << ["timestamp", "Must be an ISO8601-formatted string"]
      end
    end

    errors
  end


  [:agent_person, :agent_family, :agent_software, :agent_corporate_entity].each do |agent_type|

    JSONModel(agent_type).add_validation("check_#{agent_type.to_s}") do |hash|
      errors = []

      if hash.has_key?("dates_of_existence") && hash["dates_of_existence"].find {|d| d['date_label'] != 'existence' }
        errors << ["dates_of_existence", "Label must be 'existence' in this context"]
      end

      errors
    end

  end

  [:note_multipart, :note_bioghist].each do |schema|
    JSONModel(schema).add_validation("#{schema}_check_at_least_one_subnote") do |hash|
      if Array(hash['subnotes']).empty?
        [["subnotes", "Must contain at least one subnote"]]
      else
        []
      end
    end
  end

  def self.check_restriction_date(hash)
    errors = []

    if (rr = hash['rights_restriction'])
      begin
        begin_date = Date.strptime(rr['begin'], '%Y-%m-%d') if rr['begin']
      rescue ArgumentError => e
        errors << ["rights_restriction__begin", "must be in YYYY-MM-DD format"]
      end

      begin
        end_date = Date.strptime(rr['end'], '%Y-%m-%d') if rr['end']
      rescue ArgumentError => e
        errors << ["rights_restriction__end", "must be in YYYY-MM-DD format"]
      end

      if begin_date && end_date && end_date < begin_date
        errors << ["rights_restriction__end", "must not be before begin"]
      end
    end

    errors
  end

  if JSONModel(:note_multipart)
    JSONModel(:note_multipart).add_validation("check_restriction_date") do |hash|
      check_restriction_date(hash)
    end
  end

  JSONModel(:find_and_replace_job).add_validation("only target properties on the target schemas") do |hash|
    target_model = JSONModel(hash['record_type'].intern)
    target_property = hash['property']

    target_model.schema['properties'].has_key?(target_property) ? [] : [["property", "#{target_model.to_s} does not have a property named '#{target_property}'"]]
  end


  def self.check_location_profile(hash)
    errors = []

    # Ensure depth, width and height have no more than 2 decimal places
    ["depth", "width", "height"].each do |k|
      if !hash[k].nil? && hash[k] !~ /^\s*(?=.*[0-9])\d*(?:\.\d{1,2})?\s*$/
        errors << [k, "must be a number with no more than 2 decimal places"]
      end
    end

    errors
  end

  if JSONModel(:location_profile)
    JSONModel(:location_profile).add_validation("check_location_profile") do |hash|
      check_location_profile(hash)
    end
  end


  def self.check_field_query(hash)
    errors = []

    if (!hash.has_key?("value") || hash["value"].empty?) && hash["comparator"] != "empty"
      errors << ["value", "Must specify either a value or use the 'empty' comparator"]
    end

    errors
  end

  if JSONModel(:field_query)
    JSONModel(:field_query).add_validation("check_field_query") do |hash|
      check_field_query(hash)
    end
  end


  def self.check_date_field_query(hash)
    errors = []

    if (!hash.has_key?("value") || hash["value"].empty?) && hash["comparator"] != "empty"
      errors << ["value", "Must specify either a value or use the 'empty' comparator"]
    end

    errors
  end

  if JSONModel(:date_field_query)
    JSONModel(:date_field_query).add_validation("check_date_field_query") do |hash|
      check_field_query(hash)
    end
  end

  def self.check_rights_statement_external_document(hash)
    errors = []

    errors << ['identifier_type', 'missing required property'] if hash['identifier_type'].nil?

    errors
  end

  if JSONModel(:rights_statement_external_document)
    JSONModel(:rights_statement_external_document).add_validation("check_rights_statement_external_document") do |hash|
      check_rights_statement_external_document(hash)
    end
  end


  def self.check_assessment_monetary_value(hash)
    errors = []

    if monetary_value = hash['monetary_value']
      unless monetary_value =~ /\A[0-9]+\z/ || monetary_value =~ /\A[0-9]+\.[0-9]{1,2}\z/
        errors << ['monetary_value', "must be a number with no more than 2 decimal places"]
      end
    end

    errors
  end

  if JSONModel(:assessment)
    JSONModel(:assessment).add_validation("check_assessment_monetary_value") do |hash|
      check_assessment_monetary_value(hash)
    end
  end

  def self.check_survey_dates(hash)
    errors = []

    begin
      begin_date = parse_sloppy_date(hash['survey_begin'])
    rescue ArgumentError => e
      errors << ["survey_begin", "not a valid date"]
    end

    begin
      if hash['survey_end']
        # If padding our end date with months/days would cause it to fall before
        # the start date (e.g. if the start date was '2000-05' and the end date
        # just '2000'), use the start date in place of end.
        end_s = if begin_date && hash['survey_begin'] && hash['survey_begin'].start_with?(hash['survey_end'])
                  hash['survey_begin']
                else
                  hash['survey_end']
                end

        end_date = parse_sloppy_date(end_s)
      end
    rescue ArgumentError
      errors << ["survey_end", "not a valid date"]
    end

    if begin_date && end_date && end_date < begin_date
      errors << ["survey_end", "must not be before begin"]
    end

    errors
  end

  def self.check_standard_date(date_standardized, errors, field_name = "date_standardized")
    matches_y          = (date_standardized =~ /^[\d]{1}$/) == 0
    matches_y_mm       = (date_standardized =~ /^[\d]{1}-[\d]{2}$/) == 0
    matches_yy         = (date_standardized =~ /^[\d]{2}$/) == 0
    matches_yy_mm      = (date_standardized =~ /^[\d]{2}-[\d]{2}$/) == 0
    matches_yyy        = (date_standardized =~ /^[\d]{3}$/) == 0
    matches_yyy_mm     = (date_standardized =~ /^[\d]{3}-[\d]{2}$/) == 0
    matches_yyyy       = (date_standardized =~ /^[\d]{4}$/) == 0
    matches_yyyy_mm    = (date_standardized =~ /^[\d]{4}-[\d]{2}$/) == 0
    matches_yyyy_mm_dd = (date_standardized =~ /^[\d]{4}-[\d]{2}-[\d]{2}$/) == 0
    matches_yyy_mm_dd = (date_standardized =~ /^[\d]{3}-[\d]{2}-[\d]{2}$/) == 0
    matches_mm_yyyy    = (date_standardized =~ /^[\d]{2}-[\d]{4}$/) == 0
    matches_mm_dd_yyyy = (date_standardized =~ /^[\d]{4}-[\d]{2}-[\d]{2}$/) == 0

    errors << [field_name, "must be in YYYY[YYY][YY][Y], YYYY[YYY][YY][Y]-MM, or YYYY-MM-DD format"] unless matches_yyyy || matches_yyyy_mm || matches_yyyy_mm_dd || matches_yyy || matches_yy || matches_y || matches_yyy_mm || matches_yy_mm || matches_y_mm || matches_mm_yyyy || matches_mm_dd_yyyy || matches_yyy_mm_dd

    return errors
  end


  if JSONModel(:assessment)
    JSONModel(:assessment).add_validation("check_survey_dates") do |hash|
      check_survey_dates(hash)
    end
  end
end
