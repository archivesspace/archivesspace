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
AppConfig[:basedir] = Dir.getwd
AppConfig[:db_url] = "jdbc:derby:#{File.join(AppConfig[:basedir], "db")};create=true;aspacedemo=true"
AppConfig[:db_max_connections] = 10
