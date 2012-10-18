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


  [:archival_object, :accession].each do |type|
    if JSONModel(type)
      JSONModel(type).add_validation("#{type}_check_identifier") do |hash|
        check_identifier(hash)
      end
    end
  end

  def self.check_source(hash)
    errors = []

    if hash["authority_id"].nil? && hash["source"].nil?
      if hash["rules"].nil?
        errors << ["rules", "is required"]
      end
    elsif hash["authority_id"].nil?
      errors << ["authority_id", "is required"]
    elsif hash["source"].nil?
      errors << ["source", "is required"]
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

    if hash["date_type"] === "expression"
      errors << ["expression", "is required"] if hash["expression"].nil?
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

end
