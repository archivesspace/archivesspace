module MultipleTitlesHelper

  # titles is an array of Title in json form
  def self.determine_primary_title(titles, current_locale, parse_mixed_content = false)
    # archival objects may not have a title, so return nil if that is the case
    return nil if titles.nil? || titles.empty?

    # try to find a title with the preferred language (the language of the UI)
    pref_lang = I18n.supported_locales[current_locale.to_s]
    title = titles.find { |t| t['language'] == pref_lang }

    # fallback to the default language
    title ||= titles.find { |t| t['language'] == I18n.supported_locales[I18n.default_locale] }

    # if no preferred title can be determined, return the first title in the list
    title ||= titles[0]['title']

    parse_mixed_content ? MixedContentParser.parse(title['title'], '/').to_s : title['title']
  end

  # process largetree waypoint data, filling in the 'title' fields with the appropriate one from the titles list
  def self.waypoint_determine_primary_titles(waypoint_json, current_locale)
    waypoint_json["title"] = self.determine_primary_title(waypoint_json["titles"], current_locale, true)
    waypoint_json.delete("titles")
    waypoint_json.delete("parsed_titles")

    # the list of records is a couple of levels down in the waypoint data hash, and it's never more than one level deep
    records = waypoint_json['precomputed_waypoints'].values[0].values[0]
    records.each do |record|
      record["title"] = self.determine_primary_title(record["parsed_titles"], current_locale, true)
      # we're deleting the title lists to avoid confusion, since only one will be displayed in the tree
      record.delete("titles")
      record.delete("parsed_titles")
    end

    waypoint_json
  end

end
