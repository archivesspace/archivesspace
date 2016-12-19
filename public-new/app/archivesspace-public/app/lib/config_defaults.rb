unless $CONFIG_DEFAULTS_LOADED
  AppConfig[:archivesspace_url] = 'http://localhost:4567'
  AppConfig[:archivesspace_user] = 'admin' 
  AppConfig[:archivesspace_password] = 'admin'
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

# the following determine when the request button gets greyed out/disabled
  AppConfig[:allow_nontops] = false # disable if there is no top container

# the beginning of repository-specific customization.  The repo_id should be downcased
  AppConfig[:repos] = {}
  #AppConfig[:repos][{repo_code}] = {}
  #AppConfig[:repos][{repo_code}][:allow_nontops] = true # for a particular repository , DON'T disable
  #AppConfig[:repos][{repo_code}][:request_email] = {email address} # if it's a specific email address

  $CONFIG_DEFAULTS_LOADED = true
end
