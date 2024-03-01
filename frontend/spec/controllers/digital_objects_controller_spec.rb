# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe DigitalObjectsController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
  end

  describe 'record title field' do
    before(:each) do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = JSONModel.repository
      allow(AppConfig).to receive(:[]).and_call_original
    end

    it 'does not support mixed content by default' do
      get :new
      expect(response.body).to have_css('#digital_object_title_.form-control:not(.mixed-content)')
    end

    it 'supports mixed content when enabled' do
      allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
      get :new
      expect(response.body).to have_css('#digital_object_title_.form-control.mixed-content')
    end
  end

  describe 'spawning' do
    before(:each) do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = JSONModel.repository

      allow(AppConfig).to receive(:[]).and_call_original
      allow(controller).to receive(:user_prefs).and_return('digital_object_spawn' => true)
    end

    # test data to be reused across examples
    test_dates = [
        {
          "begin": "1999-12-31",
          "end": "2000-01-01",
          "calendar": "gregorian",
          "date_type": "inclusive",
          "era": "ce",
          "jsonmodel_type": "date",
          "label": "creation"
        }
    ]
    test_notes = [
      {
        "jsonmodel_type": "note_singlepart",
        "type": "abstract",
        "content": ["summary note"]
      },
      {
        "jsonmodel_type": "note_singlepart",
        "type": "physdesc",
        "content": ["physdesc note"]
      },
      {
        "jsonmodel_type": "note_singlepart",
        "type": "materialspec",
        "content": ["materialspec note"]
      },
      {
        "jsonmodel_type": "note_singlepart",
        "type": "physfacet",
        "content": ["physfacet note"]
      },
      {
        "jsonmodel_type": "note_multipart",
        "type": "odd",
        "subnotes": [
          {
            "content": "odd note",
            "jsonmodel_type": "note_text",
          },
        ]
      },
      {
        "jsonmodel_type": "note_multipart",
        "type": "dimensions",
        "subnotes": [
          {
              "content": "multipart dimensions note 1",
              "jsonmodel_type": "note_text",
          },
          {
              "content": "multipart dimensions note 2",
              "jsonmodel_type": "note_text",
          }
        ],
      }
    ]

    it 'can create a digital object from a resource' do
      test_timestamp = Time.now
      test_resource = create(:resource,
        title: "Digital Object From Resource Test #{test_timestamp}",
        dates: test_dates,
        notes: test_notes
      )

      get :new, params: {spawn_from_resource_id: test_resource.id, inline: true}
      result = Capybara.string(response.body)

      # standard text input fields
      expect(result).to have_field('digital_object[title]', with: "Digital Object From Resource Test #{test_timestamp}")
        .and have_field('digital_object[dates][0][begin]', with: '1999-12-31')
        .and have_field('digital_object[dates][0][end]', with: '2000-01-01')

      # a couple of select boxes
      expect(result).to have_select('digital_object[dates][0][label]', selected: 'Creation')
        .and have_select('digital_object[dates][0][date_type]', selected: 'Inclusive Dates')

      # some fields just have to be special
      expect(result.find(:id, 'digital_object_lang_materials__0__language_and_script__language_'))
        .to have_content('English')

      # collapsed notes sections
      notes_id_content_map = {
        'digital_object_notes__0_': ['Summary', 'summary note'],
        'digital_object_notes__1_': ['Physical Description', 'physdesc note'],
        'digital_object_notes__2_': ['Physical Description', 'materialspec note'],
        'digital_object_notes__3_': ['Physical Description', 'physfacet note'],
        'digital_object_notes__4_': ['Note', 'odd note'],
        'digital_object_notes__5_': ['Dimensions', 'multipart dimensions note 1'],
        'digital_object_notes__5_': ['Dimensions', 'multipart dimensions note 2'],
      }
      notes_id_content_map.each do |id, note_data|
        expect(result.find(:id, id)).to have_content(note_data[0]).and have_content(note_data[1])
      end
    end

    it 'can create a digital object from an accession' do
      test_timestamp = Time.now
      test_accession = create(:accession,
        title: "Digital Object From Accession Test #{test_timestamp}",
        dates: test_dates
      )

      get :new, params: {spawn_from_accession_id: test_accession.id, inline: true}
      result = Capybara.string(response.body)

      expect(result).to have_field('digital_object[title]', with: "Digital Object From Accession Test #{test_timestamp}")
        .and have_field('digital_object[dates][0][begin]', with: '1999-12-31')
        .and have_field('digital_object[dates][0][end]', with: '2000-01-01')

      expect(result).to have_select('digital_object[dates][0][label]', selected: 'Creation')
        .and have_select('digital_object[dates][0][date_type]', selected: 'Inclusive Dates')

      expect(result.find(:id, 'digital_object_lang_materials__0__language_and_script__language_'))
        .to have_content('English')
    end

    it 'can create a digital object from an archival object' do
      test_timestamp = Time.now
      test_resource = create(:resource)
      test_ao = create(:archival_object,
        resource: { ref: test_resource.uri },
        title: "Digital Object From Accession Test #{test_timestamp}",
        dates: test_dates,
        notes: test_notes
      )

      get :new, params: {spawn_from_archival_object_id: test_ao.id, inline: true}
      result = Capybara.string(response.body)

      expect(result).to have_field('digital_object[title]', with: "Digital Object From Accession Test #{test_timestamp}")
        .and have_field('digital_object[dates][0][begin]', with: '1999-12-31')
        .and have_field('digital_object[dates][0][end]', with: '2000-01-01')

      expect(result).to have_select('digital_object[dates][0][label]', selected: 'Creation')
        .and have_select('digital_object[dates][0][date_type]', selected: 'Inclusive Dates')

      expect(result.find(:id, 'digital_object_lang_materials__0__language_and_script__language_'))
        .to have_content('English')
    end
  end
end
