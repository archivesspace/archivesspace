require 'tmpdir'
require 'java'

class AppConfig
  @@parameters = {}

  def self.[](parameter)
    @@parameters[parameter]
  end


  def self.[]=(parameter, value)
    @@parameters[parameter] = value
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


  def self.get_preferred_config_path

    if java.lang.System.getProperty("aspace.config")
      # Explicit Java property
      java.lang.System.getProperty("aspace.config")
    elsif java.lang.System.getProperty("catalina.home")
      # Tomcat users
      File.join(java.lang.System.getProperty("catalina.home"), "conf", "config.rb")
    elsif __FILE__ !~ /^#{Dir.tmpdir}/
      File.join(File.dirname(__FILE__), "config.rb")
    else
      File.join(Dir.home, ".aspace_config.rb")
    end

  end

  def self.find_user_config
    possible_locations = [
                          get_preferred_config_path,
                          File.join(File.dirname(__FILE__), "config.rb"),
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
    "jdbc:derby:#{File.join(Dir.tmpdir, "archivesspace_demo_db")};create=true;aspacedemo=true"
  end


  def self.load_defaults
    AppConfig[:db_url] = AppConfig.demo_db_url
    AppConfig[:db_max_connections] = 10

    AppConfig[:backend_url] = "http://localhost:4567"
    AppConfig[:frontend_url] = "http://localhost:3000"

    AppConfig[:frontend_theme] = "default"
  end


  def self.reload
    @@parameters = {}

    AppConfig.load_defaults
    AppConfig.load_user_config
  end

end


## Application defaults
##
## Don't change these here: if you want to set them, copy config-example.rb to
## config.rb and override them in that file instead.

AppConfig.reload
