# frozen_string_literal: true

require_relative '../spec_helper'

describe 'RDE Templates' do
  before(:all) do
    @repo = create(:repo)
    set_repo(@repo)

    @r = create(:resource)

    @template = create(:rde_template, defaults: { 'colTitle' => 'XX' },
                       visible: [
                         "colStatus",
                         "colLevel",
                         "colOtherLevel",
                         "colPublish",
                         "colTitle",
                         "colCompId",
                         "colLanguage",
                         "colDType",
                         "colDBegin",
                         "colDEnd",
                         "colActions"
                       ],
                       order: [
                         "colStatus",
                         "colLevel",
                         "colOtherLevel",
                         "colPublish",
                         "colTitle",
                         "colCompId",
                         "colLanguage",
                         "colScript",
                         "colExpr",
                         "colDType",
                         "colDLabel",
                         "colDBegin",
                         "colDEnd",
                         "colEPortion",
                         "colENumber",
                         "colEType",
                         "colEContainer",
                         "colEPhysical",
                         "colEDimensions",
                         "colIType",
                         "colCTop",
                         "colCType2",
                         "colCInd2",
                         "colCType3",
                         "colCInd3",
                         "colNType1",
                         "colNLabel1",
                         "colNCont1",
                         "colNType2",
                         "colNLabel2",
                         "colNCont2",
                         "colNType3",
                         "colNLabel3",
                         "colNCont3",
                         "colActions"
                       ])

    @driver = Driver.get.login_to_repo($admin, @repo)
  end

  before(:each) do
    @driver.get_edit_page(@r)
    @driver.wait_for_ajax
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'can save an RDE template' do
    @driver.find_element(link: 'Rapid Data Entry').click
    @driver.wait_for_ajax

    @driver.clear_and_send_keys([:id, 'archival_record_children_children__0__title_'], 'TITLE')

    @driver.find_element(css: 'button.save-template').click

    @driver.wait_for_ajax

    @driver.clear_and_send_keys([:id, 'templateName'], 'MY TEMPLATE')

    @driver.find_element(css: '#saveTemplateForm button.btn-primary').click

    @driver.wait_for_ajax

    @driver.find_element(css: 'div.modal-footer button.btn-cancel').click

    @driver.find_element(link: 'Rapid Data Entry').click
    @driver.wait_for_ajax

    @driver.find_element(css: "button[data-id='rde_select_template']").click
    @driver.wait_for_ajax

    expect do
      @driver.find_element_with_text('//span', /MY TEMPLATE/)
    end.not_to raise_error
  end

  it 'can load an RDE template' do
    @driver.find_element(link: 'Rapid Data Entry').click
    @driver.wait_for_ajax

    multiselector_selected_cols = @driver.execute_script('return $("#rde_hidden_columns").data("multiselect").getSelected().length;')
    expect(multiselector_selected_cols).to eq 33

    @driver.find_element(css: "button[data-id='rde_select_template']").click
    @driver.wait_for_ajax
    @driver.find_element_with_text('//span', /#{@template.name}/).click
    @driver.wait_for_ajax

    expect(@driver.find_element(id: 'archival_record_children_children__0__title_').attribute('value')).to eq('XX')
    multiselector_selected_cols = @driver.execute_script('return $("#rde_hidden_columns").data("multiselect").getSelected().length;')
    expect(multiselector_selected_cols).to eq 9
  end

  it 'can delete an RDE template' do
    template = create(:rde_template)

    @driver.find_element(link: 'Rapid Data Entry').click
    @driver.wait_for_ajax

    @driver.find_element(css: "button[data-id='rde_select_template']").click
    @driver.wait_for_ajax

    expect do
      @driver.find_element_with_text('//span', /#{template.name}/)
    end.not_to raise_error

    @driver.find_element(css: 'button.manage-templates').click

    @driver.wait_for_ajax

    @driver.find_element(id: "remove_me_please_#{template.id}").click

    @driver.find_element(css: '#manageTemplatesForm button.btn-primary').click
    @driver.wait_for_ajax

    assert(10) do
      expect(@driver.find_elements(css: 'select#rde_select_template option').map { |x| x.attribute('value') }.include?(template.id)).to be_falsey
    end
  end

  it 'can display RDE templates in alpha order' do
    @driver.find_element(link: 'Rapid Data Entry').click
    @driver.wait_for_ajax

    @driver.find_element(css: "button[data-id='rde_select_template']").click

    first = @driver.find_element(css: ".dropdown-menu.open ul li:nth-child(2) span").text

    second = @driver.find_element(css: ".dropdown-menu.open ul li:nth-child(3) span").text

    expect(first <=> second).to eq(-1)
  end
end
