require 'rubygems'
require 'sequel'

require_relative 'exceptions'
require_relative 'logging'
require_relative File.join("..", "..", "config", "config")

# Load all models
Dir.glob(File.join(File.dirname(__FILE__), "..", "model", "*.rb")).each do |model|
  basename = File.basename(model, ".rb")
  require_relative File.join("..", "model", basename)
end
