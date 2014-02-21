ENV['NEW_RELIC_CONFIG_PATH'] = File.join(ASUtils.find_base_directory, "plugins", "newrelic", "frontend", "newrelic.yml")
require 'newrelic_rpm'
