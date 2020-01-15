# frozen_string_literal: true

require 'rails'
require 'spec_helper'
require 'rails_helper'

describe SearchController, type: :controller do
  before(:all) do
    @repo = create(:repo, repo_code: "search_listing_test_#{Time.now.to_i}")

    set_repo @repo

    50.times { |i|
      create(:accession, title: "Accession #{i}")
    }

    50.times { |i|
      @resource = create(:resource, title: "Resource #{i}")
      3.times { |i|
        create(:archival_object, title: "Archival Object #{i}", resource: { ref: @resource.uri })
      }
    }

    50.times { |i|
      create(:digital_object, title: "Independent DO #{i}")
    }

    run_all_indexers
  end

  xit 'returns search results in under 15 milliseconds' do
    expect {
      get :do_search
    }.to perform_under(15).ms
  end
end
