unless $CONFIG_DEFAULTS_LOADED
  AppConfig[:archivesspace_url] = 'http://localhost:4567'
  AppConfig[:archivesspace_user] = 'admin'
  AppConfig[:archivesspace_password] = 'admin'

  AppConfig[:search_results_page_size] = 10
  AppConfig[:public_url] = '/'
  AppConfig[:branding_img] = '/img/Aspace-logo.png'

  $CONFIG_DEFAULTS_LOADED = true
end
