unless $CONFIG_DEFAULTS_LOADED
  AppConfig[:archivesspace_url] = 'http://localhost:4567'
  AppConfig[:archivesspace_user] = 'admin' 
  AppConfig[:archivesspace_password] = 'admin'
  AppConfig[:search_results_page_size] = 10
  AppConfig[:public_url] = '/'
  AppConfig[:branding_img] = '/img/Aspace-logo.png'
  AppConfig[:custom] = '/config/custom' # custom directory containing locales, etc.
  AppConfig[:block_referrer] = true  # patron privacy; blocks full 'referer' when going outside the domain

# The following determine which 'tabs' are on the main horizontal menu
  AppConfig[:hide] = {}
  AppConfig[:hide][:repositories] = false
  AppConfig[:hide][:resources] = false
  AppConfig[:hide][:digital_objects] = false
  AppConfig[:hide][:accessions] = false
  AppConfig[:hide][:subjects] = false
  AppConfig[:hide][:agents] = false
  AppConfig[:hide][:classifications] = false


# The following determine globally whether the various "badges" appear on the Repository page
  # can be overriden at repository level below (e.g.:  AppConfig[:repos][{repo_code}][:hide][:counts] = true
  AppConfig[:hide][:resource_badge] = false
  AppConfig[:hide][:record_badge] = false
  AppConfig[:hide][:subject_badge] = false
  AppConfig[:hide][:agent_badge] = false
  AppConfig[:hide][:classification_badge] = false
  AppConfig[:hide][:counts] = false


# the following determine when the request button gets greyed out/disabled
  AppConfig[:requests_permitted_for_containers_only] = false # set to 'true' if you want to disable if there is no top container



# the beginning of repository-specific customization.  The repo_code should be downcased
  AppConfig[:repos] = {}
  #AppConfig[:repos][{repo_code}] = {}
  #AppConfig[:repos][{repo_code}][:requests_permitted_for_containers_only] = true # for a particular repository ,disable request
  #AppConfig[:repos][{repo_code}][:request_email] = {email address} # if it's a specific email address

  #AppConfig[:repos][{repo_code}][:hide] = {}
  #AppConfig[:repos][{repo_code}][:hide][:counts] = true


  $CONFIG_DEFAULTS_LOADED = true
end
