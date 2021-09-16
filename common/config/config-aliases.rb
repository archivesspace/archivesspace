AppConfig.add_alias(:option => :frontend_prefix,
                    :maps_to => :frontend_proxy_prefix,
                    :deprecated => true)

AppConfig.add_alias(:option => :public_prefix,
                    :maps_to => :public_proxy_prefix,
                    :deprecated => true)

AppConfig.add_deprecated(:bulk_import_rows)
AppConfig.add_deprecated(:bulk_import_size)
