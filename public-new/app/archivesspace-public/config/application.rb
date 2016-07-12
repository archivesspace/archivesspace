require_relative 'boot'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

# Maybe we won't need these?

# DISABLED BY MST # require 'active_record/railtie'
# DISABLED BY MST # require 'action_mailer/railtie'
# DISABLED BY MST # require 'active_job/railtie'
# DISABLED BY MST # require 'action_cable/engine'
# DISABLED BY MST # require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ArchivesspacePublic
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
