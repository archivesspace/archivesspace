module MultipleTitlesHelper

  @@locale_map = {'en' => 'eng', 'es' => 'spa', 'fr' => 'fre', 'de' => 'ger', 'ja' => 'jpn'}

  # titles is an array of Title in json form
  def self.determine_display_title(titles, current_locale, default_language = 'eng')
    # formal titles take precedence over all others
    titles.each { |t| return t['title'] if t['type'] == 'formal' }

    # in absence of formal titles, try to find a title with the preferred language (the language of the UI)
    pref_lang = @@locale_map[current_locale.to_s]
    titles.each { |t| return t['title'] if t['language'] == pref_lang }

    # fallback to the default language
    titles.each { |t| return t['title'] if t['language'] == default_language }

    # if no preferred title can be determined, return the first title in the list
    titles[0]['title']
  end

end
