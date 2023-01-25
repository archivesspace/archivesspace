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

  it 'can be toggled on and off for digital object file versions' do
    subform = '#digital_object_file_versions_ .subrecord-form-list > li[data-index="0"]'

    visit '/digital_objects/new'
    click_on 'Add File Version'

    within subform do
      check 'Publish?'
      toggle_expectations(@make_rep_css, @make_rep_text, @is_rep_css, @is_rep_text)
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
