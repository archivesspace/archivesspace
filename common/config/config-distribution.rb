require 'tmpdir'
require 'java'

class AppConfig
  @@parameters = {}
  @@changed_from_default = {}

  def self.[](parameter)
    parameter = resolve_alias(parameter)

    if !@@parameters.has_key?(parameter)
      raise "No value set for config parameter: #{parameter}"
    end

    val = @@parameters[parameter]

    val.respond_to?(:call) ? val.call : val
  end


  def self.[]=(parameter, value)
    parameter = resolve_alias(parameter)

    if changed?(parameter)
      $stderr.puts("WARNING: The parameter '#{parameter}' was already set")
    end

    @@changed_from_default[parameter] = true
    @@parameters[parameter] = value
  end


  def self.resolve_alias(parameter)
    if aliases[parameter]

      if deprecated_parameters[parameter]
        $stderr.puts("WARNING: The parameter '#{parameter}' is now deprecated.  Please use '#{aliases[parameter]}' instead.")
      end

      aliases[parameter]
    else
      parameter
    end
  end


  def self.aliases
    @@aliases ||= {}
  end


  def self.deprecated_parameters
    @@deprecated_parameters ||= {}
  end


  def self.has_key?(parameter)
    @@parameters.has_key?(resolve_alias(parameter))
  end


  def self.load_overrides_from_properties
    # Override defaults from the command-line if specified
    java.lang.System.get_properties.each do |property, value|
      if property =~ /aspace.config.(.*)/
        @@parameters[resolve_alias($1.intern)] = value
      end
    end
  end


  def self.load_overrides_from_environment
    # Override defaults from the environment
    ENV.each do |envvar, value|
      if envvar =~ /^APPCONFIG_/
        # Convert envvar to property: i.e. turn APPCONFIG_DB_URL into :db_url
        property = envvar.partition('_').last.downcase.to_sym
        @@parameters[resolve_alias(property)] = parse_environment_value(value)
      end
    end
  end


  def self.load_into(obj)
    @@parameters.each do |config, value|
      obj.send(:"#{config}=", value)
    end
  end


  def self.dump_sanitized
    protected_terms = /(key|password|secret)/
    Hash[@@parameters.map {|k, v|
           if k == :db_url
             [k, AppConfig[:db_url_redacted]]
           elsif k.to_s =~ protected_terms or v.to_s =~ protected_terms
             [k, "[SECRET]"]
           elsif v.is_a? (Proc)
             [k, v.call]
           else
             [k, v]
           end
         }]
  end


  def self.get_preferred_config_path

    if java.lang.System.getProperty("aspace.config")
      # Explicit Java property
      java.lang.System.getProperty("aspace.config")
    elsif ENV['ASPACE_CONFIG'] && File.exist?(ENV['ASPACE_CONFIG'])
      # Setting a system config 
      ENV['ASPACE_CONFIG']
    elsif ENV['ASPACE_LAUNCHER_BASE'] && File.exist?(File.join(ENV['ASPACE_LAUNCHER_BASE'], "config", "config.rb"))
      File.join(ENV['ASPACE_LAUNCHER_BASE'], "config", "config.rb")
    elsif java.lang.System.getProperty("catalina.base")
      # Tomcat users
      File.join(java.lang.System.getProperty("catalina.base"), "conf", "config.rb")
    elsif __FILE__.index(java.lang.System.getProperty("java.io.tmpdir")) != 0
      File.join(get_devserver_base, "config", "config.rb")
    else
      File.join(Dir.home, ".aspace_config.rb")
    end

  end

  def self.get_devserver_base
    File.join(ENV.fetch("GEM_HOME"), "..", "..")
  end

  def self.find_user_config
    possible_locations = [
                          get_preferred_config_path,
                          File.join(File.dirname(__FILE__), "config.rb"),
                          File.join(File.dirname(__FILE__), "..", "..", "config", "config.rb"),
                         ]

    possible_locations.each do |config|
      if config and File.exist?(config)
        return config
      end
    end

    nil
  end


  def self.load_user_config
    config = find_user_config

    if config
      puts "Loading ArchivesSpace configuration file from path: #{config}"
      load config
    end

    self.load_overrides_from_environment
    self.load_overrides_from_properties
  end


  def self.demo_db_url
    "jdbc:derby:#{File.join(AppConfig[:data_directory], "archivesspace_demo_db")};create=true;aspacedemo=true"
  end


  def self.read_defaults
    File.read(File.join(File.dirname(__FILE__), "config-defaults.rb"))
  end


  def self.load_defaults
    eval(read_defaults)
    @@changed_from_default = {}
  end


  def self.reload
    @@parameters = {}
    @@changed_from_default = {}

    require_relative 'config-aliases'

    AppConfig.load_defaults

    AppConfig.load_user_config
  end


  def self.changed?(parameter)
    @@changed_from_default[resolve_alias(parameter)]
  end

  def self.add_alias(options)
    target_parameter = options.fetch(:maps_to)
    alias_parameter = options.fetch(:option)

    aliases[alias_parameter] = target_parameter
    deprecated_parameters[alias_parameter] = options.fetch(:deprecated, false)
  end

  def self.parse_environment_value(value)
    value = true  if value.to_s =~ /^(T|true)$/
    value = false if value.to_s =~ /^(F|false)$/
    value = value.to_i if value =~ /^\d+$/
    value
  end

end



## Application defaults
##
## Don't change these here: if you want to set them, copy config-example.rb to
## config.rb and override them in that file instead.

AppConfig.reload
