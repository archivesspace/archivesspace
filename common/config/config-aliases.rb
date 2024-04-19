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

AppConfig.add_alias(option: :pui_email_delivery_method, maps_to: :email_delivery_method, deprecated: true)
AppConfig.add_alias(option: :pui_email_sendmail_settings, maps_to: :email_sendmail_settings, deprecated: true)
AppConfig.add_alias(option: :pui_email_perform_deliveries, maps_to: :email_perform_deliveries, deprecated: true)
AppConfig.add_alias(option: :pui_email_raise_delivery_errors, maps_to: :email_raise_delivery_errors, deprecated: true)
AppConfig.add_alias(option: :pui_email_smtp_settings, maps_to: :email_smtp_settings, deprecated: true)

AppConfig.set_options(:email_delivery_method, [:smtp, :sendmail])
