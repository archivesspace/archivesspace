# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe EventsController, type: :controller do
  render_views

  it "lets authorized users delete an event" do
    event = create(:json_event)
    user = build(:json_user).save(password: "saa2020")
    user = User.find(user)
    group = create(:json_group,
                     member_usernames: [user.username],
                     grants_permissions: ["view_repository", "update_event_record", "delete_event_record"])
    session = User.login(user.username, "saa2020")
    User.establish_session(controller, session, user.username)
    controller.send(:load_repository_list)
    post :delete, params: {id: event.id}
    expect { JSONModel(:event).find(event.id) }.to raise_error(RecordNotFound)
  end

  it "won't let unauthorized users delete an event" do
    event = create(:json_event)
    user = build(:json_user).save(password: "saa2020")
    user = User.find(user)
    group = create(:json_group,
                   member_usernames: [user.username],
                   grants_permissions: ["view_repository", "update_event_record"])
    session = User.login(user.username, "saa2020")
    User.establish_session(controller, session, user.username)
    controller.send(:load_repository_list)
    post :delete, params: {id: event.id}
    expect(JSONModel(:event).find(event.id).uri).to eq(event.uri)
  end
end
