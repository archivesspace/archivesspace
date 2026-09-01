# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'filter_parameter_logging initializer' do
  it 'configures password and session as filtered parameters' do
    expect(Rails.application.config.filter_parameters).to include(:password, :session)
  end

  it 'masks a session token so it is never written to the log in plaintext' do
    token = SecureRandom.hex(10)
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    filtered = filter.filter('session' => token, 'username' => 'test1')

    expect(filtered['session']).not_to eq(token)
    expect(filtered['username']).to eq('test1')
  end
end
