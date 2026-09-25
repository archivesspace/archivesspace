# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Resizer', js: true do
  context 'Resources' do
    before do
      login_admin
      select_repository($repo)
      visit '/resources/1'
    end

    include_context 'infinite tree resizer page setup'

    it_behaves_like 'resizing the tree pane'
  end

  context 'Digital Objects' do
    let(:now) { Time.now.to_i }
    let(:repo) { create(:repo, repo_code: "itree_resizer_do_#{now}") }
    let(:root_record) do
      create(
        :digital_object,
        title: "Resizer DO #{now}",
        digital_object_type: 'mixed_materials',
        publish: true
      )
    end

    before do
      set_repo(repo)
      login_admin
      select_repository(repo)
      visit "/digital_objects/#{root_record.id}"
    end

    include_context 'infinite tree resizer page setup'

    it_behaves_like 'resizing the tree pane'
  end

  context 'Classifications' do
    let(:now) { Time.now.to_i }
    let(:repo) { create(:repo, repo_code: "itree_resizer_class_#{now}") }
    let(:root_record) do
      create(
        :classification,
        title: "Resizer Class #{now}",
        identifier: "RESIZER-#{now}",
        publish: true
      )
    end

    before do
      set_repo(repo)
      login_admin
      select_repository(repo)
      visit "/classifications/#{root_record.id}"
    end

    include_context 'infinite tree resizer page setup'

    it_behaves_like 'resizing the tree pane'
  end
end
