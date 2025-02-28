module MultipleTitlesHelper

  @@locale_map = {'en' => 'eng', 'es' => 'spa', 'fr' => 'fre', 'de' => 'ger', 'ja' => 'jpn'}

  # titles is an array of Title in json form
  def self.determine_display_title(titles, locale)
    pref_lang = @@locale_map[locale.to_s]
    title = titles.find{|t| t['language'] == pref_lang} || titles[0]
    title['title']
  end

end
