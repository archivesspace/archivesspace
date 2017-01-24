require_relative 'spec_helper'

describe "RDE Templates" do

  before(:all) do
    @repo = create(:repo)
    set_repo(@repo)

    @r = create(:resource)
    @driver = Driver.get.login_to_repo($admin, @repo)
  end

  before(:each) do
    @driver.get_edit_page(@r)
    @driver.wait_for_ajax
  end

  after(:all) do
    @driver.quit
  end


  it "can save an RDE template" do
    @driver.find_element(:link => "Rapid Data Entry").click
    @driver.wait_for_ajax

    @driver.clear_and_send_keys([:id, "archival_record_children_children__0__title_"], "TITLE")

    @driver.find_element(:css => "button.save-template").click

    @driver.wait_for_ajax

    @driver.clear_and_send_keys([:id, "templateName"], "MY TEMPLATE")

    @driver.find_element(:css => "#saveTemplateForm button.btn-primary").click

    @driver.wait_for_ajax

    @driver.find_element(:css => "div.modal-footer button.btn-cancel").click

    @driver.find_element(:link => "Rapid Data Entry").click
    @driver.wait_for_ajax


    @driver.find_element(:css => "button[data-id='rde_select_template']").click
    @driver.wait_for_ajax

    expect {
      @driver.find_element_with_text('//span', /MY TEMPLATE/)
    }.to_not raise_error

  end


  it "can load an RDE template" do
    template = create(:rde_template, :defaults => {"colTitle" => "XX"})

    @driver.find_element(:link => "Rapid Data Entry").click
    @driver.wait_for_ajax

    @driver.find_element(:css => "button[data-id='rde_select_template']").click
    @driver.wait_for_ajax
    
    @driver.find_element_with_text('//span', /#{template.name}/).click

    @driver.find_element(:id => "archival_record_children_children__0__title_").attribute('value').should eq('XX')
  end


  it "can delete an RDE template" do
    template = create(:rde_template)

    @driver.find_element(:link => "Rapid Data Entry").click
    @driver.wait_for_ajax

    @driver.find_element(:css => "button[data-id='rde_select_template']").click
    @driver.wait_for_ajax

    expect {
      @driver.find_element_with_text('//span', /#{template.name}/)
    }.to_not raise_error

    @driver.find_element(:css => "button.manage-templates").click

    @driver.wait_for_ajax

    @driver.find_element(:id => "remove_me_please_#{template.id}").click

    @driver.find_element(:css => "#manageTemplatesForm button.btn-primary").click
    @driver.wait_for_ajax

    assert(10) {
      @driver.find_elements(:css => "select#rde_select_template option").map {|x| x.attribute("value") }.include?(template.id).should be_falsey
    }

  end
end
