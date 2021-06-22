require 'spec_helper'

class ConcernsController < ApplicationController
  include Searchable
end

describe ConcernsController do

  it 'includes AppConfig[:solr_params] in the search options' do
    AppConfig[:solr_params] = { "mm" => "3<90%", "q.op" => "AND" }
    AppConfig[:solr_params].each do |k, v|
      expect(subject.default_search_opts[k.to_sym]).to eq(v)
    end
  end

end
