# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ResourcesController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
  end

  it "sets export menu's 'include unpublished' checkbox per user preferences" do
    resource = create(:json_resource, instances: [])
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
    controller.session[:repo_id] = JSONModel.repository

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
end
