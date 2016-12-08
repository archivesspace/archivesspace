---
title: Configuring ArchivesSpace 
layout: en
permalink: /user/configuring-archivesspace/ 
---

The primary configuration for ArchivesSpace is done in the config/config.rb
file. By default, this file contains the default settings, which are indicated
by commented out lines ( indicated by the "#" in the file ). You can adjust these 
settings by adding new lines that change the default and restarting 
ArchivesSpace. Be sure that your new settings are not commented out 
( i.e. do NOT start with a "#" ), otherwise the settings will not take effect. 

```ruby

AppConfig[:default_admin_password] = "admin"
AppConfig[:data_directory] = File.join(Dir.home, "ArchivesSpace")
AppConfig[:backup_directory] = proc { File.join(AppConfig[:data_directory], "demo_db_backups") }
AppConfig[:solr_index_directory] = proc { File.join(AppConfig[:data_directory], "solr_index") }
AppConfig[:solr_home_directory] = proc { File.join(AppConfig[:data_directory], "solr_home") }
AppConfig[:solr_indexing_frequency_seconds] = 30
AppConfig[:solr_facet_limit] = 100

AppConfig[:default_page_size] = 10
AppConfig[:max_page_size] = 250

# Log level for the backend, values: (everything) debug, info, warn, error, fatal (severe only)
AppConfig[:backend_log_level] = "debug"

# A prefix added to cookies used by the application.
#
# Change this if you're running more than one instance of ArchivesSpace on the
# same hostname (i.e. multiple instances on different ports)
AppConfig[:cookie_prefix] = "archivesspace"

# The periodic indexer can run using multiple threads to take advantage of
# multiple CPU cores.
#
# By setting the next two options, you can control how many CPU cores are used,
# and the amount of memory that will be consumed by the indexing process (more
# cores and/or more records per thread means more memory used).
AppConfig[:indexer_records_per_thread] = 25
AppConfig[:indexer_thread_count] = 4
AppConfig[:indexer_solr_timeout_seconds] = 300

AppConfig[:allow_other_unmapped] = false

AppConfig[:db_url] = proc { AppConfig.demo_db_url }
AppConfig[:db_url_redacted] = proc { AppConfig[:db_url].gsub(/(user|password)=(.*?)(&|$)/, '\1=[REDACTED]\3') }
AppConfig[:db_max_connections] = proc { 20 + (AppConfig[:indexer_thread_count] * 2) }

# Set to true to log all SQL statements.  Note that this will have a performance
# impact!
AppConfig[:db_debug_log] = false

# Set to true if you have enabled MySQL binary logging
AppConfig[:mysql_binlog] = false

AppConfig[:allow_unsupported_database] = false
AppConfig[:allow_non_utf8_mysql_database] = false

AppConfig[:demo_db_backup_schedule] = "0 4 * * *"
AppConfig[:demo_db_backup_number_to_keep] = 7

AppConfig[:solr_backup_directory] = proc { File.join(AppConfig[:data_directory], "solr_backups") }
AppConfig[:solr_backup_schedule] = "0 * * * *"
AppConfig[:solr_backup_number_to_keep] = 1

AppConfig[:backend_url] = "http://localhost:8089"
AppConfig[:frontend_url] = "http://localhost:8080"

# Proxy URLs
# If you are serving user-facing applications via proxy
# (i.e., another domain or port, or via https, or for a prefix) it is
# recommended that you record those URLs in your configuration
AppConfig[:frontend_proxy_url] = proc { AppConfig[:frontend_url] }
AppConfig[:public_proxy_url] = proc { AppConfig[:public_url] }

# Don't override _prefix or _proxy_prefix unless you know what you're doing
AppConfig[:frontend_prefix] = proc { "#{URI(AppConfig[:frontend_url]).path}/".gsub(%r{/+$}, "/") }
AppConfig[:frontend_proxy_prefix] = proc { "#{URI(AppConfig[:frontend_proxy_url]).path}/".gsub(%r{/+$}, "/") }
AppConfig[:solr_url] = "http://localhost:8090"
AppConfig[:indexer_url] = "http://localhost:8091"
AppConfig[:public_url] = "http://localhost:8081"
AppConfig[:public_prefix] = proc { "#{URI(AppConfig[:public_url]).path}/".gsub(%r{/+$}, "/") }
AppConfig[:public_proxy_prefix] = proc { "#{URI(AppConfig[:public_proxy_url]).path}/".gsub(%r{/+$}, "/") }
AppConfig[:docs_url] = "http://localhost:8888"

# Setting any of the four keys below to false will prevent the associated
# applications from starting. Temporarily disabling the frontend and public
# UIs and/or the indexer may help users who are running into memory-related
# issues during migration.

AppConfig[:enable_backend] = true
AppConfig[:enable_frontend] = true
AppConfig[:enable_public] = true
AppConfig[:enable_solr] = true
AppConfig[:enable_indexer] = true
AppConfig[:enable_docs] = true

# Some use cases want the ability to shutdown the Jetty service using Jetty's
# ShutdownHandler, which allows a POST request to a specific URI to signal
# server shutdown. The prefix for this URI path is set to /xkcd to reduce the
# possibility of a collision in the path configuration. So, full path would be
# /xkcd/shutdown?token={randomly generated password}
# The launcher creates a password to use this, which is stored
# in the data directory. This is not turned on by default.
#
AppConfig[:use_jetty_shutdown_handler] = false
AppConfig[:jetty_shutdown_path] = "/xkcd"


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

AppConfig[:staff_username] = "staff_system"

AppConfig[:authentication_sources] = []

AppConfig[:realtime_index_backlog_ms] = 60000

AppConfig[:notifications_backlog_ms] = 60000
AppConfig[:notifications_poll_frequency_ms] = 1000

AppConfig[:max_usernames_per_source] = 50

AppConfig[:demodb_snapshot_flag] = proc { File.join(AppConfig[:data_directory], "create_demodb_snapshot.txt") }

AppConfig[:locale] = :en

# Report Configuration
# :report_page_layout uses valid values for the  CSS3 @page directive's
# size property: http://www.w3.org/TR/css3-page/#page-size-prop
AppConfig[:report_page_layout] = "letter landscape"
AppConfig[:report_pdf_font_paths] = proc { ["#{AppConfig[:backend_url]}/reports/static/fonts/dejavu/DejaVuSans.ttf"] }
AppConfig[:report_pdf_font_family] = "\"DejaVu Sans\", sans-serif"

# Plug-ins to load. They will load in the order specified
AppConfig[:plugins] = ['local',  'lcnaf', 'aspace-public-formats']

# URL to direct the feedback link
# You can remove this from the footer by making the value blank.
AppConfig[:feedback_url] = "http://archivesspace.org/feedback"


#
# The following are used by the aspace-public-formats plugin
# https://github.com/archivesspace/aspace-public-formats
AppConfig[:public_formats_resource_links] = []
AppConfig[:public_formats_digital_object_links] = []
AppConfig[:xsltproc_path] = nil
AppConfig[:xslt_path] = nil


# Allow an unauthenticated user to create an account
AppConfig[:allow_user_registration] = true

# Help Configuration
AppConfig[:help_enabled] = true
AppConfig[:help_url] = "http://docs.archivesspace.org"
AppConfig[:help_topic_prefix] = "/Default_CSH.htm#"


AppConfig[:shared_storage] = proc { File.join(AppConfig[:data_directory], "shared") }

# formerly known as :import_job_path
AppConfig[:job_file_path] = proc { AppConfig.has_key?(:import_job_path) ? AppConfig[:import_job_path] : File.join(AppConfig[:shared_storage], "job_files") }

# this too
AppConfig[:job_poll_seconds] = proc { AppConfig.has_key?(:import_poll_seconds) ? AppConfig[:import_poll_seconds] : 5 }

# and this
AppConfig[:job_timeout_seconds] = proc { AppConfig.has_key?(:import_timeout_seconds) ? AppConfig[:import_timeout_seconds] : 300 }

# By default, only allow jobs to be cancelled if we're running against MySQL (since we can rollback)
AppConfig[:jobs_cancelable] = proc { (AppConfig[:db_url] != AppConfig.demo_db_url).to_s }

AppConfig[:max_location_range] = 1000

# Schema Info check
# ASpace backend will not start if the db's schema_info version is not set
# correctly for this version of ASPACE. This is to ensure that all the
# migrations have run and completed before starting the app. You can override
# this check here. Do so at your own peril. 
AppConfig[:ignore_schema_info_check] = false

# Jasper Reports
# (https://community.jaspersoft.com/project/jasperreports-library)
# require compilation. This can be done at startup. Please note, if you are
# using Java 8 and you want to compile at startup, keep this setting at false,
# but be sure to use the JDK version.
AppConfig[:enable_jasper] = true
AppConfig[:compile_jasper] = true

# There are some conditions that has caused tree nodes ( ArchivalObjects, DO
# Components, and ClassificationTerms) to lose their sequence pointers and
# position setting. This will resequence these tree nodes prior to startup.
# If is recogmended that this be used very infrequently and should not be set
# to true for all startups ( as it will take a considerable amount of time )
AppConfig[:resequence_on_startup] = false

# This is a URL that points to some demo data that can be used for testing,
# teaching, etc. To use this, set an OS environment variable of ASPACE_DEMO = true
AppConfig[:demo_data_url] = "https://s3-us-west-2.amazonaws.com/archivesspacedemo/latest-demo-data.zip" 

# Expose external ids in the frontend
AppConfig[:show_external_ids] = false

#
# This sets the allowed size of the request/response header that Jetty will accept (
# anything bigger gets a 403 error ). Note if you want to jack this size up,
# you will also have to configure your Nginx/Apache  as well if
# you're using that 
AppConfig[:jetty_response_buffer_size_bytes] = 64 * 1024 
AppConfig[:jetty_request_buffer_size_bytes] = 64 * 1024 
```