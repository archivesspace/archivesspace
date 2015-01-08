require 'tmpdir'
require 'java'

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


  def self.load_overrides_from_properties
    # Override defaults from the command-line if specified
    java.lang.System.get_properties.each do |property, value|
      if property =~ /aspace.config.(.*)/
        @@parameters[$1.intern] = value
      end
    end
  end


  def self.load_into(obj)
    @@parameters.each do |config, value|
      obj.send(:"#{config}=", value)
    end
  end


  def self.dump_sanitized
    Hash[@@parameters.map {|k, v|
           if k.to_s =~ /secret/
             [k, "[SECRET]"]
           elsif v.is_a? (Proc)
             [k, v.call]
           else
             v = v.to_s.gsub(/password=.*?[$&]/, '[SECRET]')
             [k, v]
           end
         }]
  end


  def self.get_preferred_config_path

    if java.lang.System.getProperty("aspace.config")
      # Explicit Java property
      java.lang.System.getProperty("aspace.config")
    elsif java.lang.System.getProperty("ASPACE_LAUNCHER_BASE") &&
        File.exists?(File.join(java.lang.System.getProperty("ASPACE_LAUNCHER_BASE"), "config", "config.rb"))
      File.join(java.lang.System.getProperty("ASPACE_LAUNCHER_BASE"), "config", "config.rb")
    elsif java.lang.System.getProperty("catalina.base")
      # Tomcat users
      File.join(java.lang.System.getProperty("catalina.base"), "conf", "config.rb")
    elsif __FILE__.index(java.lang.System.getProperty("java.io.tmpdir")) != 0
      File.join(File.dirname(__FILE__), "config.rb")
    else
      File.join(Dir.home, ".aspace_config.rb")
    end

  end

  def self.find_user_config
    possible_locations = [
                          get_preferred_config_path,
                          File.join(File.dirname(__FILE__), "config.rb"),
                          File.join(File.dirname(__FILE__), "..", "..", "config", "config.rb"),
                         ]

    possible_locations.each do |config|
      if config and File.exists?(config)
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
