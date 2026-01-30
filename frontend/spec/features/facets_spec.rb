# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Facets', js: true do
  before(:all) do
    @now = Time.now.to_i

    @admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')
    @repository = create(:repo, repo_code: "facets_test_#{@now}")
    set_repo @repository

    @accession = create(:accession, title: "Facets Test Accession #{@now}")
    run_index_round
  end

  before(:each) do
    login_user(@admin)
    select_repository(@repository)
  end

  describe 'accessibility' do
    it 'includes record counts inside facet links for screen readers' do
      find('#global-search-button').click
      expect(page).to have_css('.search-listing-filter')

      within '.search-listing-filter' do
        expect(page).to have_css('li.facet a .record-count')
      end
    end
  end
end
