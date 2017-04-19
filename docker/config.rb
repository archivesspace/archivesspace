AppConfig[:default_admin_password] = ENV.fetch('AS_DEFAULT_ADMIN_PASSWORD', "admin")
AppConfig[:db_url] = ENV.fetch('AS_DB_URL', proc { AppConfig.demo_db_url })

AppConfig[:resequence_on_startup] = ENV.fetch('AS_RESEQUENCE_ON_STARTUP', false) == 'true' ? true : false