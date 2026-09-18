# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'filter_parameter_logging initializer' do
  it 'configures password and session as filtered parameters' do
    expect(Rails.application.config.filter_parameters).to include(:password, :session)
  end
end
