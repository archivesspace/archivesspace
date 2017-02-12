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

# PUI Indexer Settings
AppConfig[:pui_indexer_enabled] = true
AppConfig[:pui_indexing_frequency_seconds] = 30
AppConfig[:pui_indexer_records_per_thread] = 25
AppConfig[:pui_indexer_thread_count] = 1

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
AppConfig[:report_page_layout] = "letter"
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

# The number of concurrent threads available to run background jobs
# Introduced for AR-1619 - long running jobs were blocking the queue
# Resist the urge to set this to a big number!
AppConfig[:job_thread_count] = 2


# By default, only allow jobs to be cancelled if we're running against MySQL (since we can rollback)
AppConfig[:jobs_cancelable] = proc { (AppConfig[:db_url] != AppConfig.demo_db_url).to_s }

AppConfig[:max_location_range] = 1000

# Schema Info check
# ASpace backend will not start if the db's schema_info version is not set
# correctly for this version of ASPACE. This is to ensure that all the
# migrations have run and completed before starting the app. You can override
# this check here. Do so at your own peril. 
AppConfig[:ignore_schema_info_check] = false

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

# Define the fields for a record type that are inherited from ancestors
# if they don't have a value in the record itself.
# This is used in common/record_inheritance.rb and was developed to support
# the new public UI application.
# Note - any changes to record_inheritance config will require a reindex of pui
# records to take affect. To do this remove files from indexer_pui_state
AppConfig[:record_inheritance] = {
  :archival_object => {
    :inherited_fields => [
                          {
                            :property => 'title',
                            :inherit_directly => true
                          },
                          {
                            :property => 'component_id',
                            :inherit_directly => false
                          },
                          {
                            :property => 'language',
                            :inherit_directly => true
                          },
                          {
                            :property => 'dates',
                            :inherit_directly => true
                          },
                          {
                            :property => 'extents',
                            :inherit_directly => true
                          },
                          {
                            :property => 'linked_agents',
                            :inherit_if => proc {|json| json.select {|j| j['role'] == 'creator'} },
                            :inherit_directly => false
                          },
                          {
                            :property => 'notes',
                            :inherit_if => proc {|json| json.select {|j| j['type'] == 'accessrestrict'} },
                            :inherit_directly => true
                          },
                          {
                            :property => 'notes',
                            :inherit_if => proc {|json| json.select {|j| j['type'] == 'scopecontent'} },
                            :inherit_directly => false
                          },
                         ]
  }
}

# To enable composite identifiers - added to the merged record in a property _composite_identifier
# The values for :include_level and :identifier_delimiter shown here are the defaults
# If :include_level is set to true then level values (eg Series) will be included in _composite_identifier
# The :identifier_delimiter is used when joining the four part identifier for resources
#AppConfig[:record_inheritance][:archival_object][:composite_identifiers] = {
#  :include_level => false,
#  :identifier_delimiter => ' '
#}

# To configure additional elements to be inherited use this pattern in your config
#AppConfig[:record_inheritance][:archival_object][:inherited_fields] <<
#  {
#    :property => 'linked_agents',
#    :inherit_if => proc {|json| json.select {|j| j['role'] == 'subject'} },
#    :inherit_directly => true
#  }
# ... or use this pattern to add many new elements at once
#AppConfig[:record_inheritance][:archival_object][:inherited_fields].concat(
#  [
#    {
#      :property => 'subjects',
#      :inherit_if => proc {|json|
#        json.select {|j|
#          ! j['_resolved']['terms'].select { |t| t['term_type'] == 'topical'}.empty?
#        }
#      },
#      :inherit_directly => true
#    },
#    {
#      :property => 'external_documents',
#      :inherit_directly => false
#    },
#    {
#      :property => 'rights_statements',
#      :inherit_directly => false
#    },
#    {
#      :property => 'instances',
#      :inherit_directly => false
#    },
#  ])

# If you want to modify any of the default rules, the safest approach is to uncomment
# the entire default record_inheritance config and make your changes.
# For example, to stop scopecontent notes from being inherited into file or item records
# uncomment the entire record_inheritance default config above, and add a skip_if
# clause to the scopecontent rule, like this:
#  {
#    :property => 'notes',
#    :skip_if => proc {|json| ['file', 'item'].include?(json['level']) },
#    :inherit_if => proc {|json| json.select {|j| j['type'] == 'scopecontent'} },
#    :inherit_directly => false
#  },

# PUI Configurations
# TODO: Clean up configuration options

AppConfig[:pui_search_results_page_size] = 25
AppConfig[:pui_branding_img] = '/img/Aspace-logo.png'
AppConfig[:pui_block_referrer] = true # patron privacy; blocks full 'referer' when going outside the domain

# The following determine which 'tabs' are on the main horizontal menu
AppConfig[:pui_hide] = {}
AppConfig[:pui_hide][:repositories] = false
AppConfig[:pui_hide][:resources] = false
AppConfig[:pui_hide][:digital_objects] = false
AppConfig[:pui_hide][:accessions] = false
AppConfig[:pui_hide][:subjects] = false
AppConfig[:pui_hide][:agents] = false
AppConfig[:pui_hide][:classifications] = false
# The following determine globally whether the various "badges" appear on the Repository page
# can be overriden at repository level below (e.g.:  AppConfig[:repos][{repo_code}][:hide][:counts] = true
AppConfig[:pui_hide][:resource_badge] = false
AppConfig[:pui_hide][:record_badge] = false
AppConfig[:pui_hide][:subject_badge] = false
AppConfig[:pui_hide][:agent_badge] = false
AppConfig[:pui_hide][:classification_badge] = false
AppConfig[:pui_hide][:counts] = false
# Other usage examples:
# Don't display the accession ("unprocessed material") link on the main navigation menu
# AppConfig[:pui_hide][:accessions] = true

# the following determine when the request button gets greyed out/disabled
AppConfig[:pui_requests_permitted_for_containers_only] = false # set to 'true' if you want to disable if there is no top container

# Repository-specific examples.  We are using the imaginary repository code of 'foo'.  Note the lower-case
AppConfig[:pui_repos] = {}
# Example:
# AppConfig[:pui_repos][{repo_code}] = {}
# AppConfig[:pui_repos][{repo_code}][:requests_permitted_for_containers_only] = true # for a particular repository ,disable request
# AppConfig[:pui_repos][{repo_code}][:request_email] = {email address} # the email address to send any repository requests
# AppConfig[:pui_repos][{repo_code}][:hide] = {}
# AppConfig[:pui_repos][{repo_code}][:hide][:counts] = true

AppConfig[:pui_display_deaccessions] = true

# Enable / disable PUI resource/archival object page actions
AppConfig[:pui_page_actions_cite] = true
AppConfig[:pui_page_actions_bookmark] = true
AppConfig[:pui_page_actions_request] = true
AppConfig[:pui_page_actions_print] = true

# Add page actions via the configuration
AppConfig[:pui_page_custom_actions] = []
# Examples:
# Javascript action example: 
# AppConfig[:pui_page_custom_actions] << {
#   'record_type' => ['resource', 'archival_object'], # the jsonmodel type to show for
#   'label' => 'actions.do_something', # the I18n path for the action button
#   'icon' => 'fa-paw', # the font-awesome icon CSS class
#   'onclick_javascript' => 'alert("do something grand");',
# }
# # Hyperlink action example:
# AppConfig[:pui_page_custom_actions] << {
#   'record_type' => ['resource', 'archival_object'], # the jsonmodel type to show for
#   'label' => 'actions.do_something', # the I18n path for the action button
#   'icon' => 'fa-paw', # the font-awesome icon CSS class
#   'url_proc' => proc {|record| 'http://example.com/aspace?uri='+record.uri},
# }
# # Form-POST action example:
# AppConfig[:pui_page_custom_actions] << {
#   'record_type' => ['resource', 'archival_object'], # the jsonmodel type to show for
#   'label' => 'actions.do_something', # the I18n path for the action button
#   'icon' => 'fa-paw', # the font-awesome icon CSS class
#   # 'post_params_proc' returns a hash of params which populates a form with hidden inputs ('name' => 'value')
#   'post_params_proc' => proc {|record| {'uri' => record.uri, 'display_string' => record.display_string} },
#   # 'url_proc' returns the URL for the form to POST to
#   'url_proc' => proc {|record| 'http://example.com/aspace?uri='+record.uri},
#   # 'form_id' as string to be used as the form's ID
#   'form_id' => 'my_grand_action',
# }
# # ERB action example:
# AppConfig[:pui_page_custom_actions] << {
#   'record_type' => ['resource', 'archival_object'], # the jsonmodel type to show for
#   # 'erb_partial' returns the path to an erb template from which the action will be rendered
#   'erb_partial' => 'shared/my_special_action',
# }

# PUI email settings (logs emails when disabled)
AppConfig[:pui_email_enabled] = false

# See above AppConfig[:pui_repos][{repo_code}][:request_email] for setting repository email overrides
# 'pui_email_override' for testing, this email will be the to-address for all sent emails
# AppConfig[:pui_email_override] = 'testing@example.com'
# 'pui_request_email_fallback_to_address' the 'to' email address for repositories that don't define their own email
#AppConfig[:pui_request_email_fallback_to_address] = 'testing@example.com'
# 'pui_request_email_fallback_from_address' the 'from' email address for repositories that don't define their own email
#AppConfig[:pui_request_email_fallback_from_address] = 'testing@example.com'

# Example sendmail configuration: 
# AppConfig[:pui_email_delivery_method] = :sendmail
# AppConfig[:pui_email_sendmail_settings] = {
#   location: '/usr/sbin/sendmail',
#   arguments: '-i'
# }
#AppConfig[:pui_email_perform_deliveries] = true
#AppConfig[:pui_email_raise_delivery_errors] = true
# Example SMTP configuration:
#AppConfig[:pui_email_delivery_method] = :smtp
#AppConfig[:pui_email_smtp_settings] = {
#      address:              'smtp.gmail.com',
#      port:                 587,
#      domain:               'gmail.com',
#      user_name:            '<username>',
#      password:             '<password>',
#      authentication:       'plain',
#      enable_starttls_auto: true,
#}
#AppConfig[:pui_email_perform_deliveries] = true
#AppConfig[:pui_email_raise_delivery_errors] = true
