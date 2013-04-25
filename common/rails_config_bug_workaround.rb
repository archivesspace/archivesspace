class Rails::Application < Rails::Engine

  # Workaround for https://github.com/rails/rails/issues/5824

  # Initialize the application passing the given group. By default, the
  # group is :default but sprockets precompilation passes group equals
  # to assets if initialize_on_precompile is false to avoid booting the
  # whole app.
  def initialize!(group=:default) #:nodoc:
    raise "Application has been already initialized." if @initialized
    run_initializers(group, self)
    @initialized = true

    if config.allow_concurrency
      # Force lazy initialization to avoid concurrent racing conditions
      $stderr.puts("Forcing Rails configuration")
      env_config
    end

    self
  end



end
