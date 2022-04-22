require 'spec_helper'
require 'rails_helper'

describe 'Search' do

  it 'supports context-provided filter_terms that do not appear in .user_filter_terms' do
    allow(JSONModel).to receive(:repository).and_return 5

    allow(JSONModel::HTTP).to receive(:get_json) do |endpoint, criteria|
      expect(criteria["filter_term[]"]).to include({"level" => "item"}.to_json)
      expect(criteria["filter_term[]"]).to include({"resource" => "/repositories/5/resources/429"}.to_json)

      {
        "page_size"=>10,
        "first_page"=>1,
        "last_page"=>90,
        "this_page"=>1,
        "offset_first"=>1,
        "offset_last"=>10,
        "total_hits"=>0,
        "results"=> [],
        "facets" => {
          "facet_fields" => []
        }
      }
    end

    allow(JSONModel::HTTP).to receive(:get_json)
                                .with("/repositories/5/current_preferences")
                                .and_return({
                                              'defaults' => {}
                                            })

    user_criteria = {
      "filter_term[]" => [{"level" => "item"}.to_json],
    }
    context_criteria = {
      "filter_term[]" => [{"resource" => "/repositories/5/resources/429"}.to_json]
    }
    search_result_data = Search.all(5, user_criteria, context_criteria)
    query = JSON.parse(search_result_data[:criteria]["filter"])
    expect(query["query"]["subqueries"][0]["field"]).to eq "resource"
    expect(query["query"]["subqueries"][0]["value"]).to eq "/repositories/5/resources/429"
    expect(search_result_data.user_filter_terms).to eq [{"level"=>"item"}.to_json]
  end
end
