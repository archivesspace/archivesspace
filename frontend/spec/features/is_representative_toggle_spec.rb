require 'spec_helper'
require 'rails_helper'

describe 'Is Representative Toggle', js: true do
  def toggle_expectations(make_rep_css, make_rep_text, is_rep_css, is_rep_text)
    expect(page).to have_css(is_rep_css, visible: :hidden )
    expect(page).to have_css(make_rep_css, visible: true )

    click_on make_rep_text

    expect(page).to have_css(is_rep_css, visible: true )
    expect(page).to have_css(make_rep_css, visible: :hidden )

    click_on is_rep_text

    expect(page).to have_css(is_rep_css, visible: :hidden )
    expect(page).to have_css(make_rep_css, visible: true )
  end

  before(:all) do
    @make_rep_css = 'button.is-representative-toggle'
    @make_rep_text = 'Make Representative'
    @is_rep_css = 'button.is-representative-label'
    @is_rep_text = 'Representative'
  end

  before(:each) do
    login_admin
  end

  it 'can be toggled on and off for resource instances' do
    subform = '#resource_instances_ .subrecord-form-list > li[data-index="0"]'

    visit '/resources/new'
    click_on 'Add Digital Object'

    within subform do
      toggle_expectations(@make_rep_css, @make_rep_text, @is_rep_css, @is_rep_text)
    end
  end

  describe 'digital object file versions' do
    let(:thumbnail) { ['button.is-thumbnail-toggle', 'Make Display Thumbnail', 'button.is-thumbnail-label', 'Display Thumbnail'] }
    let(:link) { ['button.is-display-link-toggle', 'Make Display Link', 'button.is-display-link-label', 'Display Link'] }

    def file_version_subform(index)
      "#digital_object_file_versions_ .subrecord-form-list > li[data-index=\"#{index}\"]"
    end

    before(:each) do
      visit '/digital_objects/new'
    end

    it 'can toggle the display thumbnail and the display link on and off' do
      click_on 'Add File Version'

      within file_version_subform(0) do
        check 'Publish?'
        toggle_expectations(*thumbnail)
        toggle_expectations(*link)
      end
    end

    it 'only allows a published file version to be the display thumbnail or display link' do
      click_on 'Add File Version'

      within file_version_subform(0) do
        uncheck 'Publish?'
        expect(page).to have_css('button.is-thumbnail-toggle[disabled]')
        expect(page).to have_css('button.is-display-link-toggle[disabled]')

        check 'Publish?'
        click_on 'Make Display Thumbnail'
        expect(page).to have_css('button.is-thumbnail-label', visible: true)

        uncheck 'Publish?'
        expect(page).to have_css('button.is-thumbnail-label', visible: :hidden)
      end
    end

    it 'gives each of the display thumbnail and the display link to one file version at a time' do
      2.times { find('button', text: 'Add File Version', match: :first).click }

      within(file_version_subform(0)) { check 'Publish?' }
      within(file_version_subform(1)) { check 'Publish?' }

      within(file_version_subform(0)) { click_on 'Make Display Thumbnail' }
      within(file_version_subform(1)) { click_on 'Make Display Thumbnail' }

      within file_version_subform(0) do
        expect(page).to have_css('button.is-thumbnail-label', visible: :hidden)
        click_on 'Make Display Link'
      end

      within file_version_subform(1) do
        click_on 'Make Display Link'
        expect(page).to have_css('button.is-display-link-label', visible: true)
      end

      within(file_version_subform(0)) { expect(page).to have_css('button.is-display-link-label', visible: :hidden) }
    end

    it 'lets one file version be both the display thumbnail and the display link' do
      click_on 'Add File Version'

      within file_version_subform(0) do
        check 'Publish?'
        click_on 'Make Display Thumbnail'
        click_on 'Make Display Link'

        expect(page).to have_css('button.is-thumbnail-label', visible: true)
        expect(page).to have_css('button.is-display-link-label', visible: true)
      end
    end
  end

  it 'can be toggled on and off for agent contact details' do
    subform = '#agent_person_contact_details .subrecord-form-list > li[data-index="0"]'

    visit '/agents/agent_person/new'
    click_on 'Add Contact'

    within subform do
      toggle_expectations(
        @make_rep_css,
        'Make preferred contact',
        @is_rep_css,
        'Preferred'
      )
    end
  end
end
