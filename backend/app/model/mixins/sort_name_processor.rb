include AgentNameDates

module SortNameProcessor
  module CorporateEntity
    def self.process(json)
      result = ""

      # if a name use date is present, stringify it for inclusion
      if json['use_dates'].length > 0
        use_date = AgentNameDates::stringify_date(json['use_dates'][0])
      else
        use_date = nil
      end

      result << "#{json["primary_name"]}" if json["primary_name"]
      result << ". #{json["subordinate_name_1"]}" if json["subordinate_name_1"]
      result << ". #{json["subordinate_name_2"]}" if json["subordinate_name_2"]

      grouped = [json["number"], json["dates"]].reject{|v| v.nil?}
      result << " (#{grouped.join(" : ")})" if not grouped.empty?
      result << " (#{json["qualifier"]})" if json["qualifier"]
      result << " (#{json["sort_name_date_string"]})" if json["sort_name_date_string"]
      result << " (#{use_date})" if use_date

      result.length > 255 ? result[0..254] : result
    end
  end

  module Family
    def self.process(json)
      result = ""

      # if a name use date is present, stringify it for inclusion
      if json['use_dates'].length > 0
        use_date = AgentNameDates::stringify_date(json['use_dates'][0])
      else
        use_date = nil
      end

      result << json["family_name"] if json["family_name"]
      result << ", #{json["prefix"]}" if json["prefix"]
      result << ", #{json["dates"]}" if json["dates"]
      result << " (#{json["qualifier"]})" if json["qualifier"]
      result << " (#{json["sort_name_date_string"]})" if json["sort_name_date_string"]
      result << " (#{use_date})" if use_date
      result.length > 255 ? result[0..254] : result
    end
  end

  module Person
    def self.process(json)
      result = ""

      # if a name use date is present, stringify it for inclusion
      if json['use_dates'].length > 0
        use_date = AgentNameDates::stringify_date(json['use_dates'][0])
      else
        use_date = nil
      end

      if json["name_order"] === "inverted"
        result << json["primary_name"] if json["primary_name"]
        result << ", #{json["rest_of_name"]}" if json["rest_of_name"]
      elsif json["name_order"] === "direct"
        result << json["rest_of_name"] if json["rest_of_name"]
        result << " #{json["primary_name"]}" if json["primary_name"]
      else
        result << json["primary_name"]
      end

      result << ", #{json["prefix"]}" if json["prefix"]
      result << ", #{json["suffix"]}" if json["suffix"]
      result << ", #{json["title"]}" if json["title"]
      result << ", #{json["number"]}" if json["number"]
      result << " (#{json["fuller_form"]})" if json["fuller_form"]
      result << ", #{json["dates"]}" if json["dates"]
      result << " (#{json["qualifier"]})" if json["qualifier"]
      result << " (#{json["sort_name_date_string"]})" if json["sort_name_date_string"]
      result << " (#{use_date})" if use_date

      result.lstrip!
      result.length > 255 ? result[0..254] : result
    end
  end

  module Software
    def self.process(json)
      result = ""

      # if a name use date is present, stringify it for inclusion
      if json['use_dates'].length > 0
        use_date = AgentNameDates::stringify_date(json['use_dates'][0])
      else
        use_date = nil
      end

      result << "#{json["manufacturer"]} " if json["manufacturer"]
      result << "#{json["software_name"]}" if json["software_name"]
      result << " #{json["version"]}" if json["version"]
      result << " (#{json["qualifier"]})" if json["qualifier"]
      result << " (#{json["sort_name_date_string"]})" if json["sort_name_date_string"]
      result << " (#{use_date})" if use_date
      result.length > 255 ? result[0..254] : result
    end
  end
end
