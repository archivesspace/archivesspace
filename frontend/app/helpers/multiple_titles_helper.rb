module MultipleTitlesHelper

  @locale_map = {'en' => 'eng', 'es' => 'spa', 'fr' => 'fre', 'de' => 'ger', 'ja' => 'jpn'}

  def self.determine_display_title(titles)
    pref_lang = @locale_map[I18n.locale.to_s]
    title = titles.find{|t| t['language'] == pref_lang} || titles[0]
    title['title']
  end

end
