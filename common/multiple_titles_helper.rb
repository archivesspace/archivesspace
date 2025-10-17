require 'aspace_i18n'
require 'mixed_content_parser'

module MultipleTitlesHelper

  # titles is an array of Title hashes as typically provided by JSONModel (NOT backend Title objects)
  def self.determine_primary_title(titles, current_locale, parse_mixed_content = false)
    # archival objects may not have a title, so return nil if that is the case
    return nil if titles.nil? || titles.empty?

    # try to find a title with the preferred language (the language of the UI)
    pref_lang = I18n.supported_locales[current_locale.to_s]
    title = titles.find { |t| t['language'] == pref_lang }

    # fallback to the default language
    title ||= titles.find { |t| t['language'] == I18n.supported_locales[I18n.default_locale.to_s] }

    # if no preferred title can be determined, return the first title in the list
    title ||= titles[0]['title']

    parse_mixed_content ? MixedContentParser.parse(title['title'], '/').to_s : title['title']
  end

  # process largetree waypoint data, filling in the 'title' fields with the appropriate one from the titles list
  def self.waypoint_determine_primary_titles(waypoint_json, current_locale)
    waypoint_json["title"] = self.determine_primary_title(waypoint_json["titles"], current_locale, true)
    waypoint_json.delete("titles")
    waypoint_json["parsed_title"] = self.determine_primary_title(waypoint_json["parsed_titles"], current_locale, true)
    waypoint_json.delete("parsed_titles")

    # the list of precomputed waypoints is a couple of levels down in the waypoint data hash (if any exist)
    records = waypoint_json['precomputed_waypoints']&.values&.at(0)&.values&.at(0) || []

    records.each do |record|
      record["title"] = self.determine_primary_title(record["titles"], current_locale, true)
      record.delete("titles")
      record["parsed_title"] = self.determine_primary_title(record["parsed_titles"], current_locale, true)
      record.delete("parsed_titles")
    end

    waypoint_json
  end

  def self.subrecord_select_primary_title!(subrecord_json, current_locale)
    return if subrecord_json["title"].present?
    subrecord_json["title"] = self.determine_primary_title(subrecord_json["titles"], current_locale, true)
    subrecord_json.delete("titles")
  end

  def self.processed_waypoint(uri, params)
    waypoint_data = fetch_json(uri, params)
    processed_waypoint_data = MultipleTitlesHelper.waypoint_determine_primary_titles(waypoint_data, I18n.locale)
  end

  def self.fetch_json(uri, params = {})
    json = "{}"

    JSONModel::HTTP.stream(uri, params) do |response|
      json = response.body
    end

    JSON.parse(json)
  end

end
