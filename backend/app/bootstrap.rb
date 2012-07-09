require 'rubygems'
require 'sequel'

require_relative 'logging'
require_relative '../config/config'

# Load all models
Dir.glob(File.join(File.dirname($0), "model", "*.rb")).each do |model|
  basename = File.basename(model, ".rb")
  require_relative File.join("model", basename)
end
