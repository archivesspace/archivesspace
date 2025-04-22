require 'spec_helper'
require 'rails_helper'

describe 'Resource Tree', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "resource_tree_test_#{Time.now.to_i}")
    set_repo(@repo)
    @resource = create(:resource, id_0: "1", id_1: "2", id_2: "3", id_3: "4")
    @ao = create(:json_archival_object,
                 resource: {'ref' => @resource.uri},
                 title: "Component",
                 component_id: "abc",
                 dates: [build(:json_date, date_type: "single")]
                )
  end

  before(:each) do
    login_admin
    select_repository(@repo)
    allow(AppConfig).to receive(:[]).and_call_original
  end

  context 'when configured to display identifiers in largetree container' do
    before :each do
      allow(AppConfig).to receive(:[]).with(:display_identifiers_in_largetree_container) { true }
    end

    it "shows the record id in the tree if configured to do so" do
      visit "/resources/#{@resource.id}"
      wait_for_ajax
      ids = find_all('.resource-identifier').map { |node| node.text }
      expect(ids).to eq(["1-2-3-4", "abc"])
    end
  end

  context 'when configured not to display identifiers in largetree container' do
    before :each do
      allow(AppConfig).to receive(:[]).with(:display_identifiers_in_largetree_container) { false }
    end

    it "does not show the record id in the tree if not configured to do so" do
      visit "/resources/#{@resource.id}"
      wait_for_ajax
      expect(page).not_to have_css('.resource-identifier')
    end
  end
end
