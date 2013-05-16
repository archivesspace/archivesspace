AppConfig[:data_directory] = File.join(Dir.home, "ArchivesSpace")
AppConfig[:backup_directory] = proc { File.join(AppConfig[:data_directory], "demo_db_backups") }
AppConfig[:solr_index_directory] = proc { File.join(AppConfig[:data_directory], "solr_index") }
AppConfig[:solr_home_directory] = proc { File.join(AppConfig[:data_directory], "solr_home") }
AppConfig[:solr_indexing_frequency_seconds] = 30

AppConfig[:default_page_size] = 10
AppConfig[:max_page_size] = 250

AppConfig[:allow_other_unmapped] = false

AppConfig[:db_url] = proc { AppConfig.demo_db_url }
AppConfig[:db_max_connections] = 10

AppConfig[:allow_unsupported_database] = false

AppConfig[:demo_db_backup_schedule] = "0 4 * * *"
AppConfig[:demo_db_backup_number_to_keep] = 7

AppConfig[:solr_backup_directory] = proc { File.join(AppConfig[:data_directory], "solr_backups") }
AppConfig[:solr_backup_schedule] = "0 * * * *"
AppConfig[:solr_backup_number_to_keep] = 1

AppConfig[:backend_url] = "http://localhost:8089"
AppConfig[:frontend_url] = "http://localhost:8080"
AppConfig[:solr_url] = "http://localhost:8090"
AppConfig[:public_url] = "http://localhost:8081"

# If you have multiple instances of the backend running behind a load
# balancer, list the URL of each backend instance here.  This is used by the
# real-time indexing, which needs to connect directly to each running
# instance.
#
# By default we assume you're not using a load balancer, so we just connect
# to the regular backend URL.
#
AppConfig[:backend_instance_urls] = proc { [AppConfig[:backend_url]] }

AppConfig[:frontend_theme] = "default"
AppConfig[:public_theme] = "default"

AppConfig[:session_expire_after_seconds] = 3600

AppConfig[:search_username] = "search_indexer"

AppConfig[:public_username] = "public_anonymous"

AppConfig[:authentication_sources] = []

AppConfig[:realtime_index_backlog_ms] = 60000

AppConfig[:notifications_backlog_ms] = 60000
AppConfig[:notifications_poll_frequency_ms] = 1000

AppConfig[:max_usernames_per_source] = 50

AppConfig[:demodb_snapshot_flag] = proc { File.join(AppConfig[:data_directory], "create_demodb_snapshot.txt") }

AppConfig[:locale] = :en

# Report Configuration
AppConfig[:report_page_size] = "A4"
