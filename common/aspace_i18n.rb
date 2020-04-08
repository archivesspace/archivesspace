require 'i18n'
require 'asutils'
require 'aspace_i18n_enumeration_support'

I18n.enforce_available_locales = false # do not require locale to be in available_locales for export

I18n.load_path += ASUtils.find_locales_directories("#{AppConfig[:locale]}.yml")
I18n.load_path += ASUtils.find_locales_directories(File.join("enums", "#{AppConfig[:locale]}.yml"))

# Allow overriding of the i18n locales via the 'local' folder(s)
ASUtils.wrap(ASUtils.find_local_directories).map{|local_dir| File.join(local_dir, 'frontend', 'locales')}.reject { |dir| !Dir.exist?(dir) }.each do |locales_override_directory|
  I18n.load_path += Dir[File.join(locales_override_directory, '**' , '*.{rb,yml}')]
end

# Add report i18n locales
I18n.load_path += Dir[File.join(ASUtils.find_base_directory, 'reports', '**', '*.yml')]


module I18n

  LOCALES = {
    'en' => 'eng',
    'es' => 'spa',
    'fr' => 'fre',
    'ja' => 'jpn',
  }.sort_by { |_, v| v }.to_h.freeze

  def self.supported_locales
    LOCALES
  end

  def self.t(*args)
    self.t_raw(*args)
  end

end
