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

  [:name_person, :name_family, :name_corporate_entity, :name_software].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("#{type}_check_source") do |hash|
        check_source(hash)
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
      errors << ["begin_time", "is required"] if not hash["end_time"].nil? and hash["begin_time"].nil?
      errors << ["end_time", "is required"] if not hash["begin_time"].nil? and hash["end_time"].nil?
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

    if hash["coordinate_1_indicator"].nil? and hash["coordinate_1_label"].nil?
      errors << ["barcode", "is required"] if hash["barcode"].nil? and hash["classification"].nil?
      errors << ["classification", "is required"] if hash["classification"].nil? and hash["barcode"].nil?
    end

    if hash["barcode"].nil? and hash["classification"].nil?
      errors << ["coordinate_1_label", "is required"] if hash["coordinate_1_label"].nil?
    end

    errors << ["coordinate_1_indicator", "is required"] if hash["coordinate_1_indicator"].nil? and not hash["coordinate_1_label"].nil?
    errors << ["coordinate_2_indicator", "is required"] if hash["coordinate_2_indicator"].nil? and not hash["coordinate_2_label"].nil?
    errors << ["coordinate_3_indicator", "is required"] if hash["coordinate_3_indicator"].nil? and not hash["coordinate_3_label"].nil?

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


  def self.check_collection_management(hash)
    errors = []

    if !hash["processing_total_extent"].nil? and hash["processing_total_extent_type"].nil?
      errors << ["processing_total_extent_type", "is required if total extent is specified"]
    end

    errors
  end


  def self.check_collection_management_linked_records(hash)
    errors = []
    err = false

    if !hash.has_key?("linked_records")
      err = true
    elsif !hash["linked_records"].is_a? Array
      err = true
    elsif hash["linked_records"].length == 0
      err = true
    elsif !hash["linked_records"].first.has_key?("ref")
      err = true
    elsif hash["linked_records"].length > 1
      if hash["linked_records"].any? { |lr|
          ref = JSONModel.parse_reference(lr["ref"])
          ref.nil? || ref[:type] != "digital_object"
        }
        err = true
      end
    end

    if err
      errors << ["linked_records",
                 "must link to one accession, one resource, or one or more digital objects"]
    end

    errors
  end


  if JSONModel(:collection_management)
    JSONModel(:collection_management).add_validation("check_collection_management") do |hash|
      check_collection_management(hash)
    end
    JSONModel(:collection_management).add_validation("check_collection_management_linked_records") do |hash|
      check_collection_management_linked_records(hash)
    end
  end


  def self.check_resource(hash)
    errors = []

    if hash["level"] === "otherlevel"
      errors << ["other_level", "is required"] if hash["other_level"].nil?
    end

    errors
  end


  if JSONModel(:resource)
    JSONModel(:resource).add_validation("check_resource") do |hash|
      check_resource(hash)
    end
  end


  def self.check_archival_object(hash)
    errors = []

    if hash["level"] === "otherlevel"
      errors << ["other_level", "is required"] if hash["other_level"].nil?
    end

    errors
  end


  if JSONModel(:archival_object)
    JSONModel(:archival_object).add_validation("check_archival_object") do |hash|
      check_archival_object(hash)
    end
  end
end
