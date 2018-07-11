require_relative 'spec_helper'
require 'ostruct'

describe "User management" do

  before(:all) do
    @test_user = OpenStruct.new(:username => "test_user_#{Time.now.to_i}",
                                :password => "123456")
    @user_props = {
      :email => "#{@test_user.username}@aspace.org",
      :first_name => "first_name_#{Time.now.to_i}",
      :last_name => "last_name_#{Time.now.to_i}",
      :telephone => "555-555-5555",
      :title => "title",
      :department => "dept",
      :additional_contact => "ac_#{Time.now.to_i}"}

    @driver = Driver.get
  end

  after(:each) do
    @driver.logout
  end

  after(:all) do
    @driver.quit
  end


  it "can create a user account" do
    @driver.login($admin)
    
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Users").click

    @driver.find_element(:link, "Create User").click

    @driver.clear_and_send_keys([:id, "user_username_"], @test_user.username)
    @driver.clear_and_send_keys([:id, "user_name_"], @test_user.username)

    @user_props.each do |k,val|
      @driver.clear_and_send_keys([:id, "user_#{k.to_s}_"], val)
    end


    @driver.clear_and_send_keys([:id, "user_password_"], @test_user.password)
    @driver.clear_and_send_keys([:id, "user_confirm_password_"], @test_user.password)

    @driver.find_element(:id, "user_is_admin_").click

    @driver.find_element(:id, 'create_account').click
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /User Created: /)
  end

  it "doesn't delete user information after the new user logins" do
    run_index_round
    @driver.login(@test_user)

    @driver.find_element(:css => "span.user-label").text.should match(/#{@test_user.username}/)

    @driver.logout.login($admin)

    @driver.find_element(:link, 'System').click
    @driver.click_and_wait_until_gone(:link, "Manage Users")

    @driver.find_paginated_element(:xpath => "//td[contains(text(), '#{@test_user.username}')]/following-sibling::td/div/a").click

    @user_props.each do |k,val|
      assert(5) { @driver.find_element(:css=> "#user_#{k.to_s}_").attribute('value').should match(val) }
    end

    @driver.find_element(:id, "user_is_admin_" ).attribute("checked").should be_truthy
  end

  it "doesn't allow another user to edit the global admin or a system account" do
    @driver.login(@test_user)

    ['1', '2'].each do |user_id|
      assert (5) {
        @driver.navigate.to("#{$frontend}/users/#{user_id}/edit")
        @driver.find_element_with_text('//div[contains(@class, "alert-danger")]', /Access denied/)
      }
    end
  end

  it "doesn't allow you to edit the user short names" do
    @driver.login($admin)

    assert (5) {
      @driver.navigate.to("#{$frontend}/users/1/edit")
      @driver.find_element(:id, "user_username_").attribute("readonly").should eq("true")
    }
  end

end
