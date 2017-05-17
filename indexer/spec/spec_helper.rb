require 'rspec'
require 'jsonmodel'

class IndexerEnumSource
  def values_for(*args)
    args
  end

  def valid?(*stuff)
    true
  end
end

JSONModel::init(:enum_source => IndexerEnumSource.new)

require_relative '../../backend/spec/factories'
# require_relative "spec_helper_methods"

FactoryGirl.define do
  to_create{|instance| instance}
end

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include JSONModel
end
