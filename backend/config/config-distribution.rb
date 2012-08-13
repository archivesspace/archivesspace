class AppConfig
  BASEDIR = File.join(File.dirname(__FILE__), "..")
  DB_URL = "jdbc:derby:#{File.join(BASEDIR, "db")};create=true;aspacedemo=true"
  DB_MAX_CONNECTIONS = 10
end
