require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
# require "active_model/railtie"
# require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_view/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"

require 'java'
require 'config/config-distribution'
require 'asutils'

require "rails_config_bug_workaround"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ArchivesSpacePublic
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.assets.enabled = true
    config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')


    # config.paths["app/controllers"].concat(ASUtils.find_local_directories("public/controllers"))

    config.action_controller.relative_url_root = AppConfig[:public_proxy_prefix].sub(/\/$/, '')


    config.i18n.default_locale = AppConfig[:locale]

    # Load the shared 'locales'
    ASUtils.find_locales_directories.map{|locales_directory| File.join(locales_directory)}.reject { |dir| !Dir.exist?(dir) }.each do |locales_directory|
      config.i18n.load_path += Dir[File.join(locales_directory, '**' , '*.{rb,yml}')]
    end

    # Override with any local locale files
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    # Allow overriding of the i18n locales via the local folder(s)
    if not ASUtils.find_local_directories.blank?
      ASUtils.find_local_directories.map{|local_dir| File.join(local_dir, 'public', 'locales')}.reject { |dir| !Dir.exist?(dir) }.each do |locales_override_directory|
        config.i18n.load_path += Dir[File.join(locales_override_directory, '**' , '*.{rb,yml}')]
      end
    end

    config.encoding = "utf-8"

    config.filter_parameters += [:password]

    config.active_support.escape_html_entities_in_json = true

    config.assets.enabled = true

    AppConfig.load_into(config)
  end

  class SessionGone < StandardError
  end


  class SessionExpired < StandardError
  end

end
