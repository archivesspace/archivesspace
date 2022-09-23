# frozen_string_literal: true

require_relative '../spec_helper'
require 'ostruct'

describe 'User management' do
  before(:all) do
    @test_user = OpenStruct.new(username: "test_user_#{Time.now.to_i}",
                                password: '123456')
    @user_props = {
      email: "#{@test_user.username}@aspace.org",
      first_name: "first_name_#{Time.now.to_i}",
      last_name: "last_name_#{Time.now.to_i}",
      telephone: '555-555-5555',
      title: 'title',
      department: 'dept',
      additional_contact: "ac_#{Time.now.to_i}"
    }

    @driver = Driver.get
  end

  after(:each) do
    @driver.logout
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'can create a user account', :skip => "UPGRADE skipping for green CI" do
    @driver.login($admin)

    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, 'Manage Users').click

    @driver.find_element(:link, 'Create User').click

    @driver.clear_and_send_keys([:id, 'user_username_'], @test_user.username)
    @driver.clear_and_send_keys([:id, 'user_name_'], @test_user.username)

    @user_props.each do |k, val|
      @driver.clear_and_send_keys([:id, "user_#{k}_"], val)
    end

    @driver.clear_and_send_keys([:id, 'user_password_'], @test_user.password)
    @driver.clear_and_send_keys([:id, 'user_confirm_password_'], @test_user.password)

    @driver.find_element(:id, 'user_is_admin_').click

    @driver.find_element(:id, 'create_account').click
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /User Created: /)
  end

  it "doesn't delete user information after the new user logins", :skip => "UPGRADE skipping for green CI" do
    run_index_round
    @driver.login(@test_user)

    expect(@driver.find_element(css: 'span.user-label').text).to match(/#{@test_user.username}/)

    @driver.logout.login($admin)

    @driver.find_element(:link, 'System').click
    @driver.click_and_wait_until_gone(:link, 'Manage Users')

    @driver.find_element(:id, "edit_#{@test_user.username}").click

    @user_props.each do |k, val|
      assert(5) { expect(@driver.find_element(css: "#user_#{k}_").attribute('value')).to match(val) }
    end

    expect(@driver.find_element(:id, 'user_is_admin_').attribute('checked')).to be_truthy
  end

  it "doesn't allow another user to edit the global admin or a system account", :skip => "UPGRADE skipping for green CI" do
    @driver.login(@test_user)

    %w[1 2].each do |user_id|
      assert (5) do
        @driver.navigate.to("#{$frontend}/users/#{user_id}/edit")
        @driver.find_element_with_text('//div[contains(@class, "alert-danger")]', /Access denied/)
      end
    end
  end

  it "doesn't allow you to edit the user short names", :skip => "UPGRADE skipping for green CI" do
    @driver.login($admin)

    assert (5) do
      @driver.navigate.to("#{$frontend}/users/1/edit")
      expect(@driver.find_element(:id, 'user_username_').attribute('readonly')).to eq('true')
    end
  end

  it "allows user to edit their own account", :skip => "UPGRADE skipping for green CI" do
    @driver.login(@test_user)

    @driver.navigate.to("#{$frontend}/users/edit_self")

    @driver.clear_and_send_keys([:id, 'user_name_'], "New Username")
    @driver.clear_and_send_keys([:id, 'user_password_'], "newpassword123")
    @driver.clear_and_send_keys([:id, 'user_confirm_password_'], "newpassword123")

    @driver.find_element(:id, 'create_account').click

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /User Saved/)
  end
end
