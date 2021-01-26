module SortNameProcessor
  module Utils
    def self.first_date(data, date_type)
      return nil unless data[date_type] && data[date_type]&.count.positive?

      stringify_date(data[date_type][0])
    end

    # @avatar382 comments:
    # input is an array of JSONModel date objects corresponding to the dates of existence for the parent agent
    # output is a string form of date object for use in sort name string

    # processing in pseudocode
    # if date expression
    #   return date expression
    # else if begin and end date
    #   return begin date year - end date year
    # else
    #   return begin date year
    def self.stringify_date(date_json)
      date_substring = ""

      if date_json["date_type_structured"] == "single"
        std = date_json["structured_date_single"]['date_standardized']
        exp = date_json["structured_date_single"]['date_expression']

        # only grab the year
        std = std.split("-")[0] unless std.nil?

        if exp
          date_substring = exp
        elsif std
          s_type = date_json["structured_date_single"]["date_standardized_type"]
          date_substring = std
          date_substring << " #{I18n.t('enumerations.date_standardized_type.' + s_type)}" unless s_type == "standard"
        end
      elsif date_json["date_type_structured"] == "range"
        b_std = date_json["structured_date_range"]['begin_date_standardized']
        b_exp = date_json["structured_date_range"]['begin_date_expression']
        e_std = date_json["structured_date_range"]['end_date_standardized']
        e_exp = date_json["structured_date_range"]['end_date_expression']

        b_s_type = date_json["structured_date_range"]["begin_date_standardized_type"]
        e_s_type = date_json["structured_date_range"]["end_date_standardized_type"]

        # only grab the years
        b_std = b_std.split("-")[0] unless b_std.nil?
        e_std = e_std.split("-")[0] unless e_std.nil?

        if b_exp && e_exp
          date_substring = b_exp + "-" + e_exp
        elsif b_exp
          date_substring = b_exp
        elsif b_std && e_std
          b_std += " #{I18n.t('enumerations.date_standardized_type.' + b_s_type)}" unless b_s_type == "standard"
          e_std += " #{I18n.t('enumerations.date_standardized_type.' + e_s_type)}" unless e_s_type == "standard"
          date_substring = b_std + "-" + e_std
        elsif b_std
          b_std += " #{I18n.t('enumerations.date_standardized_type.' + b_s_type)}" unless b_s_type == "standard"
          date_substring = b_std
        end
      end

      return date_substring
    end
  end

  module CorporateEntity
    def self.process(json, extras = {})
      result = ""

      result << "#{json["primary_name"]}" if json["primary_name"]
      result << ". #{json["subordinate_name_1"]}" if json["subordinate_name_1"]
      result << ". #{json["subordinate_name_2"]}" if json["subordinate_name_2"]

      grouped = [json["number"], json["dates"]].reject{|v| v.nil?}
      result << ", #{grouped.join(" : ")}" if not grouped.empty?
      result << " (#{json["qualifier"]})" if json["qualifier"]

      dates = json['dates'].nil? ? SortNameProcessor::Utils.first_date(extras, 'dates_of_existence') : nil
      result << " (#{dates})" if dates
      result << " (#{json["location"]})" if json["location"]

      result.length > 255 ? result[0..254] : result
    end
  end

  module Family
    def self.process(json, extras = {})
      result = ""

      result << json["family_name"] if json["family_name"]
      result << ", #{json["prefix"]}" if json["prefix"]
      result << ", #{json["dates"]}" if json["dates"]
      result << " (#{json["qualifier"]})" if json["qualifier"]

      dates = json['dates'].nil? ? SortNameProcessor::Utils.first_date(extras, 'dates_of_existence') : nil
      result << " (#{dates})" if dates

      result.length > 255 ? result[0..254] : result
    end
  end

  module Person
    def self.process(json, extras = {})
      result = ""

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

      dates = json['dates'].nil? ? SortNameProcessor::Utils.first_date(extras, 'dates_of_existence') : nil
      result << " (#{dates})" if dates

      result.lstrip!
      result.length > 255 ? result[0..254] : result
    end
  end

  module Software
    def self.process(json, extras = {})
      result = ""

      result << "#{json["manufacturer"]} " if json["manufacturer"]
      result << "#{json["software_name"]}" if json["software_name"]
      result << " #{json["version"]}" if json["version"]
      result << " (#{json["qualifier"]})" if json["qualifier"]

      dates = json['dates'].nil? ? SortNameProcessor::Utils.first_date(extras, 'dates_of_existence') : nil
      result << " (#{dates})" if dates

      result.length > 255 ? result[0..254] : result
    end
  end
end
