# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Staff login throttling', js: true do
  let(:username) { "throttle-user-#{SecureRandom.hex(4)}" }

  before do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:frontend_login_throttle_limit).and_return(1)
    Rack::Attack.reset!
  end

  after { Rack::Attack.reset! }

  def attempt_login(password)
    within 'form.login' do
      fill_in 'username', with: username
      fill_in 'password', with: password
      click_button 'Sign In'
    end
    wait_for_ajax
  end

  it 'shows a too many attempts message, not the login failed message, when the username is blocked' do
    visit '/logout'
    attempt_login('wrong')
    expect(page).to have_css('.alert-danger', text: 'Login attempt failed')

    attempt_login('wrong')
    expect(page).to have_css('.alert-warning', text: 'Too many failed login attempts')
    expect(page).to have_no_css('.alert-danger')
  end
end
