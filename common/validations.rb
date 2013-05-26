require 'time'

module JSONModel::Validations
  extend JSONModel


  def self.check_identifier(hash)
    ids = (0...4).map {|i| hash["id_#{i}"]}

    errors = []

    if ids.reverse.drop_while {|elt| elt.to_s.empty?}.any?{|elt| elt.to_s.empty?}
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

  # Specification:
  # https://www.pivotaltracker.com/story/show/41430143
  def self.check_source(hash)
    errors = []

    if hash["source"].nil?
      if hash["rules"].nil? 
        errors << ["rules", "is required when 'source' is blank"]
        errors << ["source", "is required when 'rules' is blank"]
      elsif hash["authority_id"]
        errors << ["source", "is required if there is an authority id"]
      end
    end

    errors
  end
  
  def self.check_name(hash)
    errors = []
    errors << ["sort_name", "Property is required but was missing"] if hash["sort_name"].nil? and !hash["sort_name_auto_generate"]
    errors
  end

  [:name_person, :name_family, :name_corporate_entity, :name_software].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("#{type}_check_source") do |hash|
        check_source(hash)
      end
      JSONModel(type).add_validation("#{type}_check_name") do |hash|
        check_name(hash)
      end
    end
  end


  def self.check_date(hash)
    errors = []

    if hash["expression"].nil? and hash["date_type"].nil?
      errors << ["date_type", "is required"]
    elsif hash["date_type"] === "single"
      errors << ["begin", "is required"] if hash["begin"].nil?
    elsif hash["date_type"] === "inclusive" || hash["date_type"] === "bulk"
      errors << ["begin", "is required"] if hash["begin"].nil?
      errors << ["end", "is required"] if hash["end"].nil?

      # check that end isn't before begin
      # need to expand to full date+time - choosing to use rfc3339, though just doing a string compare

      if hash["begin"] && hash["end"]
        bt = "#{hash["begin"]}"
        2.times { bt << '-01' if bt !~ /\-\d\d\-\d\d/ }
        bt << "T00:00:00+00:00"

        et = "#{hash["end"]}"
        et << '-12' if et !~ /\-\d\d/
        et << '-31' if et !~ /\-\d\d\-\d\d/
        et << "T23:59:59+00:00"

        errors << ["end", "must not be before begin"] if Time.parse(et) < Time.parse(bt)
      end
    end

    errors
  end


  if JSONModel(:date)
    JSONModel(:date).add_validation("check_date") do |hash|
      check_date(hash)
    end
  end


  def self.check_rights_statement(hash)
    errors = []

    if hash["rights_type"] === "intellectual_property"
      errors << ["ip_status", "is required"] if hash["ip_status"].nil?
      errors << ["jurisdiction", "is required"] if hash["jurisdiction"].nil?
    elsif hash["rights_type"] === "license"
      errors << ["license_identifier_terms", "is required"] if hash["license_identifier_terms"].nil?
    elsif hash["rights_type"] === "statute"
      errors << ["statute_citation", "is required"] if hash["statute_citation"].nil?
      errors << ["jurisdiction", "is required"] if hash["jurisdiction"].nil?
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

    errors << ["end_date", "is required"] if hash["end_date"].nil? and hash["status"] === "previous"

    errors
  end


  if JSONModel(:container_location)
    JSONModel(:container_location).add_validation("check_container_location") do |hash|
      check_container_location(hash)
    end
  end


  def self.check_instance(hash)
    errors = []

    if hash["instance_type"] === "digital_object"
      errors << ["digital_object", "is required"] if hash["digital_object"].nil?
    elsif hash["instance_type"]
      errors << ["container", "is required"] if hash["container"].nil?
    end

    errors
  end


  if JSONModel(:instance)
    JSONModel(:instance).add_validation("check_instance") do |hash|
      check_instance(hash)
    end
  end


  def self.check_collection_management(hash)
    errors = []

    if !hash["processing_total_extent"].nil? and hash["processing_total_extent_type"].nil?
      errors << ["processing_total_extent_type", "is required if total extent is specified"]
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
      if !hash[k].nil? and hash[k] !~ /^\-?\d{0,9}\.\d{1,2}$/
        errors << [k, "must be a number with no more than nine digits and two decimal places"]
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
    JSONModel(:resource).add_validation("check_resource_otherlevel", :warning) do |hash|
      check_otherlevel(hash)
    end
  end


  def self.check_otherlevel(hash)
    warnings = []

    if hash["level"] === "otherlevel"
      warnings << ["other_level", "is required"] if hash["other_level"].nil?
    end
    
    warnings
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
    
    JSONModel(:archival_object).add_validation("check_archival_object_otherlevel", :warning) do |hash|
      check_otherlevel(hash);
    end
    
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

end
