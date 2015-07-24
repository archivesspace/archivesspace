require_relative 'spec_helper'

describe "RDE Templates" do

  before(:all) do
    backend_login

    @repo = create(:repo)
    set_repo(@repo.uri)

    @r = create(:resource)
  end

  before(:each) do

    login_to_repo("admin", "admin", @repo)

    $driver.get("#{$frontend}#{@r.uri.sub(/\/repositories\/\d+/, '')}/edit")
    $driver.wait_for_ajax
  end

  after(:each) do
    logout
  end


  it "can save an RDE template" do
    $driver.find_element(:link => "Rapid Data Entry").click
    $driver.wait_for_ajax

    $driver.clear_and_send_keys([:id, "archival_record_children_children__0__title_"], "TITLE")

    $driver.find_element(:css => "button.save-template").click

    $driver.wait_for_ajax

    $driver.clear_and_send_keys([:id, "templateName"], "MY TEMPLATE")

    $driver.find_element(:css => "#saveTemplateForm button.btn-primary").click

    $driver.wait_for_ajax

    $driver.find_element(:css => "div.modal-footer button.btn-cancel").click

    $driver.find_element(:link => "Rapid Data Entry").click
    $driver.wait_for_ajax


    $driver.find_element(:css => "button[data-id='rde_select_template']").click
    $driver.wait_for_ajax

    expect {
      $driver.find_element_with_text('//span', /MY TEMPLATE/)
    }.to_not raise_error

  end


  it "can load an RDE template" do
    template = create(:rde_template, :defaults => {"colTitle" => "XX"})

    $driver.find_element(:link => "Rapid Data Entry").click
    $driver.wait_for_ajax

    $driver.find_element(:css => "button[data-id='rde_select_template']").click
    $driver.wait_for_ajax
    
    $driver.find_element_with_text('//span', /#{template.name}/).click

    $driver.find_element(:id => "archival_record_children_children__0__title_").attribute('value').should eq('XX')
  end


  it "can delete an RDE template" do
    template = create(:rde_template)

    $driver.find_element(:link => "Rapid Data Entry").click
    $driver.wait_for_ajax

    $driver.find_element(:css => "button[data-id='rde_select_template']").click
    $driver.wait_for_ajax

    expect {
      $driver.find_element_with_text('//span', /#{template.name}/)
    }.to_not raise_error

    $driver.find_element(:css => "button.manage-templates").click

    $driver.wait_for_ajax

    $driver.find_element(:xpath => "//tr[td/text()='#{template.name}']/td[2]/button").click

    $driver.find_element(:css => "#manageTemplatesForm button.btn-primary").click
    $driver.wait_for_ajax

    assert(10) {
      $driver.find_elements(:css => "select#rde_select_template option").map {|x| x.attribute("value") }.include?(template.id).should be_falsey
    }

  end
end
