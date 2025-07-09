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

end
