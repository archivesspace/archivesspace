require 'aspace-rails/compressor'
require 'aspace-rails/asset_path_rewriter'
ArchivesSpace::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  config.eager_load = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  # in test we will mimic production to check if things are passing right... 
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true
  config.assets.js_compressor = ASpaceCompressor.new(:js)
  config.assets.css_compressor = ASpaceCompressor.new(:css)


  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  # config.action_mailer.delivery_method = :test

  # Raise exception on mass assignment protection for Active Record models
  # config.active_record.mass_assignment_sanitizer = :strict

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
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

  if AppConfig[:frontend_proxy_prefix] && AppConfig[:frontend_proxy_prefix].length > 1
   AssetPathRewriter.new.rewrite(AppConfig[:frontend_proxy_prefix],
                                File.expand_path('../../../public', __FILE__ ),
                                'public' )
  end

end
