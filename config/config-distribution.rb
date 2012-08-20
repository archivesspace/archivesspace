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


  def self.load_user_config
    config = File.join(File.dirname(__FILE__), "config.rb")

    if java.lang.System.getProperty("aspace.config")
      config = java.lang.System.getProperty("aspace.config")
    end

    if File.exists?(config)
      require config
    end

    self.load_overrides_from_properties
  end

end


## Application defaults
##
## Don't change these here: if you want to set them, copy config-example.rb to
## config.rb and override them in that file instead.

AppConfig[:db_url] = "jdbc:derby:#{File.join(Dir.tmpdir, "archivesspace_demo_db")};create=true;aspacedemo=true"
AppConfig[:db_max_connections] = 10

AppConfig[:backend_url] = "http://localhost:4567"
AppConfig[:frontend_url] = "http://localhost:3000"


AppConfig.load_user_config
