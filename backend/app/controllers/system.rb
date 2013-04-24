class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/system/demo_db_snapshot')
  .description("Create a snapshot of the demo database if the file '#{File.basename(AppConfig[:demodb_snapshot_flag])}' exists in the data directory")
  .permissions([])
  .returns([200, "OK"]) \
  do
    flag = AppConfig[:demodb_snapshot_flag]
    if File.exists?(flag)
      Log.info("Starting backup of embedded demo database")
      DB.demo_db_backup
      Log.info("Backup of embedded demo database completed!")

      File.unlink(flag)
      [200, {}, "OK"]
    else
      Log.info("The flag file '#{flag}' doesn't exist")
      [403, {}, "DENIED"]
    end
  end

end
