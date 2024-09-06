require_relative 'boot'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'action_mailer/railtie'

require 'asutils'
require_relative 'initializers/plugins'

require 'aspace_logger'

# Maybe we won't need these?

# DISABLED BY MST # require 'active_record/railtie'
# DISABLED BY MST # require 'active_job/railtie'
# DISABLED BY MST # require 'action_cable/engine'
# DISABLED BY MST # require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups(:assets => %w(development test)))
#ASUtils.load_pry_aliases

module ArchivesSpacePublic
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add plugin controllers and models
    config.paths["app/controllers"].concat(ASUtils.find_local_directories("public/controllers"))
    config.paths["app/models"].concat(ASUtils.find_local_directories("public/models"))

    config.action_controller.relative_url_root = AppConfig[:public_proxy_prefix].sub(/\/$/, '')

    # Load the shared 'locales'
    ASUtils.find_locales_directories.map {|locales_directory| File.join(locales_directory)}.reject { |dir| !Dir.exist?(dir) }.each do |locales_directory|
      I18n.load_path += Dir[File.join(locales_directory, '**' , '*.{rb,yml}')].reject {|file| file =~ /public/}
    end

    I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    # Load the PUI-specific locales to have them take priority over any others
    ASUtils.find_locales_directories.map {|locales_directory| File.join(locales_directory)}.reject { |dir| !Dir.exist?(dir) }.each do |locales_directory|
      I18n.load_path += Dir[File.join(locales_directory, 'public', '**' , '*.{rb,yml}')]
    end

    # Allow overriding of the i18n locales via the 'local' folder(s)
    if not ASUtils.find_local_directories.blank?
      ASUtils.find_local_directories.map {|local_dir| File.join(local_dir, 'public', 'locales')}.reject { |dir| !Dir.exist?(dir) }.each do |locales_override_directory|
        I18n.load_path += Dir[File.join(locales_override_directory, '**' , '*.{rb,yml}')]
      end
    end

    config.i18n.default_locale = AppConfig[:locale]

    # Add template static assets to the path
    if not ASUtils.find_local_directories.blank?
      ASUtils.find_local_directories.map {|local_dir| File.join(local_dir, 'public', 'assets')}.reject { |dir| !Dir.exist?(dir) }.each do |static_directory|
        config.assets.paths.unshift(static_directory)
      end
    end

    # add fonts to the asset path
    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    # Logging
    config.log_formatter = ::Logger::Formatter.new
    logger = if AppConfig.changed?(:pui_log)
               ASpaceLogger.new(AppConfig[:pui_log])
             else
               ASpaceLogger.new($stderr)
             end
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)


    config.log_level = AppConfig[:pui_log_level].intern

    # mailer configuration
    if AppConfig[:pui_email_enabled]
      config.action_mailer.delivery_method = AppConfig[:email_delivery_method]
      config.action_mailer.perform_deliveries = AppConfig[:email_perform_deliveries]
      config.action_mailer.raise_delivery_errors = AppConfig[:email_raise_delivery_errors]

      if config.action_mailer.delivery_method == :sendmail
        if AppConfig.has_key? :email_sendmail_settings
          config.action_mailer.smtp_settings = AppConfig[:email_sendmail_settings]
        end
      end
      if config.action_mailer.delivery_method == :smtp
        config.action_mailer.smtp_settings = AppConfig[:email_smtp_settings]
      end
    else
      config.action_mailer.delivery_method = :test
      config.action_mailer.perform_deliveries = false
    end

  end
end

# Load plugin init.rb files (if present)
ASUtils.order_plugins(ASUtils.find_local_directories('public')).each do |dir|
  init_file = File.join(dir, "plugin_init.rb")
  if File.exist?(init_file)
    load init_file
  end
end
