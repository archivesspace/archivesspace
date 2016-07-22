require 'aspace-rails/compressor'


ArchivesSpace::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = true 
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true
  config.assets.js_compressor = ASpaceCompressor.new(:js)
  config.assets.css_compressor = ASpaceCompressor.new(:css)


  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false 

  # Generate digests for assets URLs
  config.assets.digest = true

  # If a prefix has been specified, use it!
  config.assets.prefix = AppConfig[:frontend_proxy_prefix] + "assets"
  config.assets.manifest = File.join(Rails.public_path, "assets")

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

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

  # Precompile additional assets
  config.assets.precompile = [Proc.new {|file|
                                file =~ /.*\.js$/ or
                                file =~ /jstree/ or
                                file =~ /css-spinners\/.*/ or
                                file =~ /codemirror\/.*/ or
                                file =~ /codemirror\/util\/.*/ or
                                file =~ /.*\.(png|jpg|gif)$/ or
                                file =~ /.*\.(eot|svg|ttf|woff|woff2)$/ or
                                file =~ /themes\/.*\/(application|bootstrap).css/ or
                                file =~ /rde.css/ or
                                file =~ /jquery.kiketable.colsizable.css/ or
                                file =~ /jquery.tablesorter\/.*/ or 
                                file =~ /bootstrap-select\/.*/
                              }]

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  config.threadsafe!

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


if AppConfig[:frontend_prefix] != "/"
  require 'action_dispatch/middleware/static'

  # The default file handler doesn't know about asset prefixes and returns a 404.  Make it strip the prefix before looking for the path on disk.
  module ActionDispatch
    class FileHandler
      alias :match_orig :match?
      def match?(path)
        prefix = AppConfig[:frontend_prefix]
        modified_path = path.gsub(/^#{Regexp.quote(prefix)}/, "/")
        match_orig(modified_path)
      end
    end
  end
end
