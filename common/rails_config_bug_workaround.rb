class RailsConfigBugWorkaround
  def self.use_secret(cookie_secret)
    @secret = ENV['DISABLE_STARTUP'] ? nil : Digest::SHA1.hexdigest(AppConfig[cookie_secret])
  end

  def self.secret_token
    @secret
  end
end


class Rails::Application < Rails::Engine
  # Workaround for bug:
  #
  #   https://github.com/rails/rails/issues/4652
  #
  # But there's an additional problem here: the 'config' object might not have
  # been initialised at the point env_config is first called.  The 'inherited'
  # method of Rails::Application makes the app's Application class available
  # as Rails.application, so it's possible for other threads to invoke
  # Application.env_config in the time period between when the Application
  # class is created and when all of its config initialisers have finished.
  #
  # Here we get around this by removing our reliance on config.secret_token.
  #
  def env_config
    @app_env_config ||= super.merge({
                                      "action_dispatch.parameter_filter" => config.filter_parameters,
                                      "action_dispatch.secret_token" => RailsConfigBugWorkaround.secret_token,
                                      "action_dispatch.show_exceptions" => config.action_dispatch.show_exceptions,
                                      "action_dispatch.show_detailed_exceptions" => config.consider_all_requests_local,
                                      "action_dispatch.logger" => Rails.logger,
                                      "action_dispatch.backtrace_cleaner" => Rails.backtrace_cleaner
                                    })
  end
end
