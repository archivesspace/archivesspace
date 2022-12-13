# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ResourcesController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
  end

  let(:default_values) {
    DefaultValues.new(
      JSONModel(:default_values).from_hash({
        'record_type': 'resource',
        'defaults': {
          'publish': true,
          "extents": [{"portion": "whole"}],
          "lang_materials": [{"language_and_script": {"language": "eng", "script": "Latn"}}],
          "notes": [{"jsonmodel_type": "note_multipart", "type": "scopecontent", "publish": true, "subnotes": [
            {"jsonmodel_type": "note_text", "content": "Scope and content!", "publish": true}]}
          ]
        }
      })
    )
  }

  it "sets export menu's 'include unpublished' checkbox per user preferences" do
    resource = create(:json_resource, instances: [])

    apply_session_to_controller(controller, 'admin', 'admin')
    # pretend preference is include_unpublished
    allow(controller).to receive(:user_prefs).and_return('include_unpublished' => true)
    get :edit, params: {id: resource.id, inline: true}
    expect(response.body).to match /id="include-unpublished"[^>]+checked/
    expect(response.body).to match /id="include-unpublished-marc"[^>]+checked/

    # pretend preference is not to include_unpublished
    allow(controller).to receive(:user_prefs).and_return('include_unpublished' => false)
    get :edit, params: {id: resource.id, inline: true}
    expect(response.body).not_to match /id="include-unpublished"[^>]+checked/
    expect(response.body).not_to match /id="include-unpublished-marc"[^>]+checked/
  end

  it "applies default values to a new resource" do
    apply_session_to_controller(controller, 'admin', 'admin')
    allow(controller).to receive(:user_defaults).with('resource').and_return(default_values)
    get :new
    result = Capybara.string(response.body)
    result.find(:css, '#resource_extents__0__portion_ option[@selected="selected"]') do |selected|
      expect(selected.text).to eq('Whole')
    end
    result.find(:css,
      '#resource_lang_materials__0__language_and_script__script_ option[@selected="selected"]'
    ) do |selected|
      expect(selected.text).to eq('Latin')
    end
  end

  it "spawns a resource from an accession with default values" do
    accession = create(:json_accession, extents: [ build(:json_extent, portion: 'part') ])

    apply_session_to_controller(controller, 'admin', 'admin')
    allow(controller).to receive(:user_defaults).with('resource').and_return(default_values)
    get :new, params: {accession_id: accession.id, inline: true}
    expect(response.body).to match /spawned from Accession/
    result = Capybara.string(response.body)
    result.find(:css, '#resource_extents__0__portion_ option[@selected="selected"]') do |selected|
      expect(selected.text).not_to eq('Whole') # from defaults
      expect(selected.text).to eq('Part') # from accession
    end
    result.find(:css,
      '#resource_lang_materials__0__language_and_script__script_ option[@selected="selected"]'
    ) do |selected|
      expect(selected.text).to eq('Latin')
    end
    # we should have 3 notes (scope, content, condition)
    expect(result.find_all(:css, '#resource_notes_ li[data-object-name="note"]').count).to eq 3
    result.find(:css, '#resource_notes__0_') do |selected|
      expect(selected.text).to match /Scope and content!/
    end
  end
end
