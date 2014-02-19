ENV['NEW_RELIC_CONFIG_PATH'] = File.join(ASUtils.find_base_directory, "plugins", "newrelic", "public", "newrelic.yml")
require 'newrelic_rpm'
