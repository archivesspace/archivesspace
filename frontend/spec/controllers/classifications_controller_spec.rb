# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ClassificationsController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
    controller.session[:repo_id] = JSONModel.repository
  end

  let(:classification) do
    resource = create(:json_resource)
    create(:json_classification, linked_records: [{ 'ref' => resource.uri }])
  end

  def capture_resolve_opts
    opts = nil
    allow(JSONModel(:classification)).to receive(:find).and_wrap_original do |original, *args|
      opts ||= args[1]
      original.call(*args)
    end
    yield
    opts
  end

  describe 'resolving linked records' do
    # ANW-652: A classification can have thousands of linked records. The show page
    # lists them through a separate paginated search (see _show_inline.html.erb), so
    # resolving them when finding the record is wasted work that slows the page down.
    it 'does not resolve linked_records for the inline show page' do
      id = classification.id

      opts = capture_resolve_opts do
        get :show, params: { id: id, inline: true }
      end

      expect(response).to be_successful
      expect(opts['resolve[]']).not_to be_empty
      expect(opts['resolve[]']).not_to include('linked_records')
    end

    it 'still resolves linked_records for the inline edit form' do
      id = classification.id

      opts = capture_resolve_opts do
        get :edit, params: { id: id, inline: true }
      end

      expect(response).to be_successful
      expect(opts['resolve[]']).to include('linked_records')
    end
  end
end
