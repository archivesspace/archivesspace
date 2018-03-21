$CLASSPATH << File.expand_path('../../build/*', __dir__)
$CLASSPATH << File.expand_path('../../common/lib/*', __dir__)
$:.unshift( File.expand_path('../../common', __dir__) )

if ENV['COVERAGE_REPORTS'] == 'true'
  require 'simplecov'
  SimpleCov.start('rails') do
    add_filter '/spec'
  end
  SimpleCov.command_name 'spec'

end 

require 'aspace_gems'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)                                                                                                                            

require 'rspec/rails'

