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
      errors << ["end_time", "is required"] if not hash["begin_time"].nil?
    end

    errors
  end


  if JSONModel(:date)
    JSONModel(:date).add_validation("check_date") do |hash|
      check_date(hash)
    end
  end

end
