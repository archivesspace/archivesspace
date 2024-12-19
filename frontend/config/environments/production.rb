require 'aspace-rails/compressor'
require 'aspace-rails/asset_path_rewriter'

ArchivesSpace::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  config.eager_load = true

  # WARNING: Don't enable `consider_all_requests_local` without doing some
  # research first.  When this was turned on, Rails 5.0.1 would flush the
  # LookupContext DetailsKey cache between requests, which has the effect of
  # generating a new set of cache keys for partials that are rendered.  The
  # knock-on effect of this is that all partials get recompiled and cached,
  # which over time leads to an accumulation of compiled partials and an OOM
  # condition.
  #
  # See: actionview-5.0.1/lib/action_view/lookup_context.rb for the DetailsKey
  # that contains this key cache, and
  # actionview-5.0.1/lib/action_view/railtie.rb for the initializer that clears
  # it on each request when `consider_all_requests_local` is set.
  #
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true
  config.assets.js_compressor = ASpaceCompressor.new(:js)
  config.assets.css_compressor = ASpaceCompressor.new(:css)


  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  #config.assets.manifest = File.join(Rails.public_path, "assets")

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = AppConfig[:force_ssl]

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

end


# https://aaronblohowiak.telegr.am/blog_posts/precompiling-assets-under-jruby
if defined?(ExecJS) && system('which node >/dev/null 2>/dev/null')
  puts "Using Node ExecJS runtime"
  ExecJS.runtime = ExecJS::Runtimes::Node
end

# The default file handler doesn't know about asset prefixes and returns a 404.  Make it strip the prefix before looking for the path on disk.
if AppConfig[:frontend_proxy_prefix] && AppConfig[:frontend_proxy_prefix].length > 1
  require 'action_dispatch/middleware/static'
  module ActionDispatch
    class FileHandler
      private

      def find_file(path_info, accept_encoding:)
        prefix = AppConfig[:frontend_proxy_prefix]
        each_candidate_filepath(path_info) do |filepath, content_type|
          filepath = filepath.gsub(/^#{Regexp.quote(prefix)}/, "/")
          if response = try_files(filepath, content_type, accept_encoding: accept_encoding)
            return response
          end
        end
      end
    end
  end

  AssetPathRewriter.new.rewrite(AppConfig[:frontend_proxy_prefix], File.dirname(__FILE__))
end

ActiveSupport::Deprecation.silenced = true
