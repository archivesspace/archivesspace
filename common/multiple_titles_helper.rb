require 'aspace_i18n'

module MultipleTitlesHelper

  # titles is an array of Title in json form
  def self.determine_primary_title(titles, current_locale)
    # archival objects may not have a title, so return nil if that is the case
    return nil if titles.nil? || titles.empty?

    # TODO: delete if the decision to remove this rule sticks
    # formal titles take precedence over all others
    # titles.each { |t| return t['title'] if t['type'] == 'formal' }

    # in absence of formal titles, try to find a title with the preferred language (the language of the UI)
    pref_lang = I18n.supported_locales[current_locale.to_s]
    titles.each { |t| return t['title'] if t['language'] == pref_lang }

    # fallback to the default language
    titles.each { |t| return t['title'] if t['language'] == I18n.supported_locales[I18n.default_locale] }

    # if no preferred title can be determined, return the first title in the list
    titles[0]['title'] unless titles.empty?
  end

end
