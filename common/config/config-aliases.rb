AppConfig.add_alias(:option => :frontend_prefix,
                    :maps_to => :frontend_proxy_prefix,
                    :deprecated => true)

AppConfig.add_alias(:option => :public_prefix,
                    :maps_to => :public_proxy_prefix,
                    :deprecated => true)

AppConfig.add_deprecated(:bulk_import_rows)
AppConfig.add_deprecated(:bulk_import_size)
AppConfig.add_deprecated(:solr_home_directory)

AppConfig.add_deprecated(:solr_backup_directory)
AppConfig.add_deprecated(:solr_index_directory)
AppConfig.add_deprecated(:solr_backup_schedule)
AppConfig.add_deprecated(:solr_backup_number_to_keep)

AppConfig.set_options(:pui_repositories_sort, [:display_string, :position])
