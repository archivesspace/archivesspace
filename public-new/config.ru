# This file is used by Rack-based servers to start the application.

require "aspace_gems"
ASpaceGems.setup

require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
