Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.public_file_server.enabled = true

  # Don't care if the mailer can't send.
  # DISABLED BY MST # config.action_mailer.raise_delivery_errors = false

  # DISABLED BY MST # config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  # DISABLED BY MST # config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # If we're running with a prefix, write our on-the-fly compiled assets to the
  # right spot.  NOTE: Don't enable this for production, as it's handled
  # differently there due to precompilation.
  config.assets.prefix = AppConfig[:public_proxy_prefix] + "assets"

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Allow the web console to work in the browser
  config.web_console.allowed_ips = ['172.18.0.0/16', '172.27.0.0/16', '0.0.0.0/0']

  # Infinite Tree and Records config
  config.infinite_tree_waypoint_size = 200
  config.infinite_records_waypoint_size = 20
  config.infinite_records_main_max_concurrent_waypoint_fetches = 20
  config.infinite_records_worker_max_concurrent_waypoint_fetches = 100
  # Beware! Don't set this number over 1350, Chromium's limit of fetches per process.
  # Anything more and it throws `net::ERR_INSUFFICIENT_RESOURCES`, returning
  # `undefined` per fetch.
end
