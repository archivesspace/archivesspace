unless $CONFIG_DEFAULTS_LOADED
  AppConfig[:archivesspace_url] = 'http://localhost:4567'
  AppConfig[:archivesspace_user] = 'CHANGETHIS' 
  AppConfig[:archivesspace_password] = 'CHANGETHIS'
  AppConfig[:search_results_page_size] = 10
  AppConfig[:public_url] = '/'
  AppConfig[:branding_img] = '/img/Aspace-logo.png'

# The following determine whether the various "badges" appear on the Repository page
  AppConfig[:hide_resource_badge] = false
  AppConfig[:hide_record_badge] = false
  AppConfig[:hide_subject_badge] = false
  AppConfig[:hide_agent_badge] = false
  AppConfig[:hide_classification_badge] = false

# The following determine which 'tabs' are on the main horizontal menu
  AppConfig[:hide_repository_tab] = false
  AppConfig[:hide_resource_tab] = false
  AppConfig[:hide_digital_object_tab] = false
  AppConfig[:hide_unprocessed_tab] = false
  AppConfig[:hide_subject_tab] = false
  AppConfig[:hide_agent_tab] = false
  AppConfig[:hide_classification_tab] = false


  $CONFIG_DEFAULTS_LOADED = true
end
