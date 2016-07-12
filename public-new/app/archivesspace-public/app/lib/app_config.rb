class AppConfig
  @@parameters = {}
  @@changed_from_default = {}

  def self.[](parameter)
    if !@@parameters.has_key?(parameter)
      raise "No value set for config parameter: #{parameter}"
    end

    val = @@parameters[parameter]

    val.respond_to?(:call) ? val.call : val
  end

  def self.[]=(parameter, value)
    @@changed_from_default[parameter] = true
    @@parameters[parameter] = value
  end

  def self.has_key?(parameter)
    @@parameters.has_key?(parameter)
  end

  def self.find_user_config
    path = File.absolute_path(File.join(Rails.root, '..', '..', 'config', 'config.rb'))
    if File.exist?(path)
      path
    else
      nil
    end
  end

  def self.load_user_config
    config = find_user_config

    if config
      puts "Loading configuration file from path: #{config}"
      load config
    end
  end

  def self.load_defaults
    eval(File.read(File.join(File.dirname(__FILE__), "config_defaults.rb")))
  end

  def self.reload
    @@parameters = {}

    AppConfig.load_defaults
    @@changed_from_default = {}

    AppConfig.load_user_config
  end

  def self.changed?(parameter)
    @@changed_from_default[parameter]
  end

end


## Application defaults
##
## Don't change these here: if you want to set them, copy config-example.rb to
## config.rb and override them in that file instead.

AppConfig.reload
