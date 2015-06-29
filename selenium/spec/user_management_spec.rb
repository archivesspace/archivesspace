require_relative 'spec_helper'

describe "User management" do

  before(:all) do
    @user = nil
  end

  before(:all) do
    @test_user = "test_user_#{Time.now.to_i}"
    @test_pass = "123456"
    @user_props = {
      :email => "#{@test_user}@aspace.org", :first_name => "first_#{@test_user}",
      :last_name => "last_#{@test_user}", :telephone => "555-555-5555",
      :title => "title_#{@test_user}", :department => "dept_#{@test_user}",
      :additional_contact => "ac_#{@test_user}"}
  end

  after(:each) do
    logout
  end


  it "can create a user account" do
    login("admin", "admin")
    $driver.find_element(:link, 'System').click
    $driver.find_element(:link, "Manage Users").click

    $driver.find_element(:link, "Create User").click

    $driver.clear_and_send_keys([:id, "user_username_"], @test_user)
    $driver.clear_and_send_keys([:id, "user_name_"], @test_user)

    @user_props.each do |k,val|
      $driver.clear_and_send_keys([:id, "user_#{k.to_s}_"], val)
    end


    $driver.clear_and_send_keys([:id, "user_password_"], @test_pass)
    $driver.clear_and_send_keys([:id, "user_confirm_password_"], @test_pass)

    $driver.find_element(:id, 'create_account').click
    $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /User Created: /)
  end

  it "doesn't delete user information after the new user logins" do
    run_index_round
    $driver.navigate.refresh
    sleep 5
    $driver.find_element(:link, "Sign In").click
    $driver.clear_and_send_keys([:id, 'user_password'], @test_pass)
    $driver.clear_and_send_keys([:id, 'user_username'], @test_user)

    $driver.find_element(:id, 'login').click
    sleep 5
    $driver.wait_for_ajax
    assert(5) { $driver.find_element(:css => "span.user-label").text.should match(/#{@test_user}/) }

    logout

    $driver.navigate.refresh
    login("admin", "admin")
    $driver.find_element(:link, 'System').click
    $driver.find_element(:link, "Manage Users").click


    $driver.find_paginated_element(:xpath => "//td[contains(text(), '#{@test_user}')]/following-sibling::td/div/a").click

    @user_props.each do |k,val|
      assert(5) { $driver.find_element(:css=> "#user_#{k.to_s}_").attribute('value').should match(val) }
    end
  end


  it "doesn't allow you to edit the user short names" do
    login("admin", "admin")

    $driver.attempt(10) { |attempt|
      attempt.navigate.to("#{$frontend}/users/1/edit")
      attempt.find_element(:id, "user_username_")
    }.attribute("readonly").should eq("true")
  end

end
