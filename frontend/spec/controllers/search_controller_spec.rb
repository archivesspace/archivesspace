# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe SearchController, type: :controller do
  render_views

  before :each do
    allow(controller).to receive(:unauthorised_access).and_return(true)
    allow(controller).to receive(:load_repository_list).and_return([])
  end

  it 'supports chaining an :aq query field in the request params' do
    search = class_double("Search").
               as_stubbed_const

    allow(search).to receive(:all) { |_, params|
      expect(params.keys).to include "aq"
      aq = JSON.parse(params["aq"])
      expect(aq["query"]["subqueries"].map { |sq| sq["field"] }).to eq ["foo", "unfoo"]
    }

    get :advanced_search, params: { aq: JSON({ query: { field: 'foo', value: 'bar', jsonmodel_type: 'field_query' } }),
                                    advanced: true,
                                    f1: "unfoo",
                                    v1: "unbar",
                                    op1: "AND",
                                  }, format: :json
  end
end
