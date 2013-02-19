# Load the rails application
require File.expand_path('../application', __FILE__)


# There's currently an issue between Rails and Rack > 1.4.2 that cause Rails to
# print a harmless SECURITY ERROR on startup.  Future versions of Rails will
# work around this, but for now we suppress the error.
#
# See: https://github.com/rails/rails/issues/7372
#
if Rails::VERSION::STRING == "3.2.6"
  require 'action_dispatch/middleware/session/abstract_store'

  module ActionDispatch
    module Session
      module Compatibility
        def initialize(app, options = {})
          options[:key] ||= '_session_id'
          # FIXME Rack's secret is not being used
          options[:secret] ||= SecureRandom.hex(30)
          super
        end
      end
    end
  end
end

# Initialize the rails application
ArchivesSpace::Application.initialize!
