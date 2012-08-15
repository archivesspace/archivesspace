require 'tmpdir'

class AppConfig
  @@parameters = {}

  def self.[](parameter)
    @@parameters[parameter]
  end


  def self.[]=(parameter, value)
    @@parameters[parameter] = value
  end
end


## Application defaults
AppConfig[:db_url] = "jdbc:derby:#{File.join(Dir.tmpdir, "archivesspace_demo_db")};create=true;aspacedemo=true"
AppConfig[:db_max_connections] = 10
