require_relative 'spec_helper'
require 'ostruct'

describe "Users and authentication" do

  before(:all) do
    @user = build(:user)
    @driver = Driver.get
  end

  after(:all) do
    @driver.quit
  end


  it "fails logins with invalid credentials" do
    @driver.login(OpenStruct.new(:username => "oopsie",
                                 :password => "daisy"),
                  expect_fail = true)

    @driver.find_element(:css => "p.alert-danger").text.should eq('Login attempt failed')

    @driver.find_element(:link, "Sign In").click
  end


  it "can register a new user" do
    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:link, "Register now").click

    @driver.clear_and_send_keys([:id, "user_username_"], @user.username)
    @driver.clear_and_send_keys([:id, "user_name_"], @user.name)
    @driver.clear_and_send_keys([:id, "user_password_"], "testuser")
    @driver.clear_and_send_keys([:id, "user_confirm_password_"], "testuser")

    @driver.find_element(:id, 'create_account').click

    assert(5) { @driver.find_element(:css => "span.user-label").text.should match(/#{@user.username}/) }
  end


  it "but they have no repositories yet!" do
    assert(5) {
      @driver.ensure_no_such_element(:link, "Select Repository")
    }
    @driver.logout
  end


  it "allows the admin user to become a different user" do
    @driver.login($admin)

    @driver.find_element(:css, '.user-container a.btn').click
    @driver.find_element(:link, "Become User").click
    @driver.clear_and_send_keys([:id, "select-user"], @user.username)
    @driver.find_element(:css, "#new_become_user .btn-primary").click
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Successfully switched users/)

    @driver.logout
  end

  it "prevents any user from becoming the global admin" do
    @driver.login($admin)

    @driver.find_element(:css, '.user-container a.btn').click
    @driver.find_element(:link, "Become User").click
    @driver.clear_and_send_keys([:id, "select-user"], "admin")
    @driver.find_element(:css, "#new_become_user .btn-primary").click
    @driver.find_element_with_text('//div[contains(@class, "alert-danger")]', /Failed to switch/)

    @driver.logout
  end

end
