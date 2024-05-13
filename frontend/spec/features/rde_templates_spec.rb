# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'RDE Templates', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:all) do
    @repository = create(:repo, repo_code: "resources_test_#{Time.now.to_i}")
    set_repo @repository
  end

  before(:each) do
    login_user(admin_user)
    select_repository(@repository)
  end

  it 'can save an RDE template' do
    now = Time.now.to_i
    resource = create(:resource)
    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'

    element = find('#archival_record_children_children__0__title_')
    element.fill_in with: "Rapid Data Entry Title #{now}"

    click_on 'Save as Template'

    element = find('#templateName')
    element.fill_in with: "Template Name #{now}"

    click_on 'Save Template'

    click_on 'Cancel'

    click_on 'Rapid Data Entry'

    element = find("button[data-id='rde_select_template']")
    element.click

    expect(page).to have_text "Template Name #{now}"
  end

  it 'can load an RDE template' do
    now = Time.now.to_i
    resource = create(:resource)
    template = create(
      :rde_template,
      defaults: { 'colTitle' => 'XX' },
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
      ]
    )

    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'

    element = find('#rde_hidden_columns', visible: false)
    selected_options = element.all('option[selected]', visible: false)
    expect(selected_options.length).to eq 45

    element = find("button[data-id='rde_select_template']")
    element.click

    element = find(:xpath, "//*[text()='#{template.name}']")
    element.click

    element = find('#rde_hidden_columns', visible: false)
    selected_options = element.all('option[selected]', visible: false)
    expect(selected_options.length).to eq 9
  end

  it 'can delete an RDE template' do
    now = Time.now.to_i
    resource = create(:resource)
    template = create(:rde_template)
    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'

    element = find("button[data-id='rde_select_template']")
    element.click

    expect(page).to have_text template.name

    click_on 'Remove Templates'
    expect(page).to have_css '#manageTemplatesForm'

    element = find("#remove_me_please_#{template.id}")
    element.click

    click_on 'Confirm Removal'
    sleep 3
    expect(page).to_not have_css '#manageTemplatesForm'

    elements = all('select#rde_select_template option', visible: false)
    option_values = elements.map { |x| x.value }
    expect(option_values.include?(template.id)).to eq false
  end

  it 'can display RDE templates in alpha order' do
    now = Time.now.to_i
    resource = create(:resource)
    template = create(:rde_template)
    run_index_round

    visit "resources/#{resource.id}/edit"
    click_on 'Rapid Data Entry'
    click_on 'Remove Templates'
    templates = all(:xpath, "//tr[contains(., 'AAA') or contains(., 'BBB') or contains(., 'CCC')]")
    templates.each do |template|
      template.find('input').click
    end
    click_on 'Confirm Removal'

    template = create(:rde_template, name: "CCC #{now}")
    template = create(:rde_template, name: "BBB #{now}")
    template = create(:rde_template, name: "AAA #{now}")

    visit "resources/#{resource.id}/edit"
    click_on 'Rapid Data Entry'

    element = find("button[data-id='rde_select_template']")
    element.click

    first = find(".dropdown-menu.open ul li:nth-child(2) span:first-of-type").text
    second = find(".dropdown-menu.open ul li:nth-child(3) span:first-of-type").text
    third = find(".dropdown-menu.open ul li:nth-child(4) span:first-of-type").text

    expect(first).to eq "AAA #{now}"
    expect(second).to eq "BBB #{now}"
    expect(third).to eq "CCC #{now}"
  end
end
