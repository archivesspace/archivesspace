# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe WelcomeController, type: :controller do
  it 'should welcome all guests' do
    expect(get(:index)).to have_http_status(200)
  end
end
