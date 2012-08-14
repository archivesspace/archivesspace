require_relative 'config-distribution'

class AppConfig
  # You can override the default configuration options by setting them here.
  # For example, something like like this if you want to use MySQL:
  DB_URL = "jdbc:mysql://localhost:3306/archivesspace?user=as&password=as123"
end
