# frozen_string_literal: true

require 'spec_helper'
# ./build/run backend:test -Dexample='Enumerations API'

RSpec.describe 'Enumerations API' do
  describe 'GET /config/enumerations/csv' do
    it 'retrieves a list of all non-suppressed enumerations as csv' do
      get '/config/enumerations/csv'
      csv = CSV.parse(last_response.body)
      expect(last_response.status).to eq(200)
      expect(csv[0]).to eq Enumeration::CSV_HEADERS
      expect(csv.size - 1).to eq EnumerationValue.where(suppressed: 0).count
    end
  end
end
