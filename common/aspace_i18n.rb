require 'i18n'
require 'asutils'
require 'aspace_i18n_enumeration_support'

class Backend < I18n::Backend::Simple
  include I18n::Backend::Fallbacks
end

I18n.enforce_available_locales = false # do not require locale to be in available_locales for export

I18n.load_path += ASUtils.find_locales_directories("#{AppConfig[:locale]}.yml")
I18n.load_path += ASUtils.find_locales_directories(File.join("enums", "#{AppConfig[:locale]}.yml"))

# Allow overriding of the i18n locales via the 'local' folder(s)
plugin_locale_directories = ASUtils.wrap(ASUtils.find_local_directories).map {|local_dir| File.join(local_dir, 'frontend', 'locales')}.reject { |dir| !Dir.exist?(dir) }
ASUtils.order_plugins(plugin_locale_directories).each do |locales_override_directory|
  I18n.load_path += Dir[File.join(locales_override_directory, '**' , '*.{rb,yml}')]
end

# Add report i18n locales
I18n.load_path += Dir[File.join(ASUtils.find_base_directory, 'reports', '**', '*.yml')]

I18n.default_locale = AppConfig[:locale]
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
I18n.fallbacks = I18n::Locale::Fallbacks.new(de: :en, es: :en, fr: :en, ja: :en)
module I18n

  LOCALES = {
    'en' => 'eng',
    'es' => 'spa',
    'fr' => 'fre',
    'ja' => 'jpn',
    'de' => 'ger'
  }.sort_by { |_, v| v }.to_h.freeze

  def self.supported_locales
    LOCALES
  end

  def self.prioritize_plugins!
    self.load_path = self.load_path.reject { |p| p.match /plugins\// } + self.load_path.reject { |p| !p.match /plugins\// }
  end

end
