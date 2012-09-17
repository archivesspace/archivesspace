require_relative "../../config/config-distribution"

if (AppConfig[:db_url] =~ /jdbc:derby:(.*?);.*aspacedemo=true$/)
  dir = $1

  if File.directory?(dir) and File.exists?(File.join(dir, "seg0"))
    puts "Nuking demo database: #{dir}"
    sleep(5)
    FileUtils.rm_rf(dir)
    exit
  end
end

require_relative "../../backend/app/main"

Sequel.connect(AppConfig[:db_url],
               :max_connections => AppConfig[:db_max_connections],
               # :loggers => [Logger.new($stderr)]
               ) do |db|
  if ARGV.length > 0 and ARGV[0] == "nuke"
    DBMigrator.nuke_database(db)
  end

  puts "Running migrations..."
  DBMigrator.setup_database(db)
  puts "All done."
end
