require "rspec"
require 'jsonmodel'
require 'factory_girl'

require_relative '../app/lib/periodic_indexer'

include JSONModel

JSONModel::init(:client_mode => true, :strict_mode => true,
                :url => AppConfig[:backend_url],
                :priority => :high)

JSONModel::HTTP.current_backend_session = 'donaldtrump'


module JSONModel
  module HTTP
    def self.get_json(*args)
      (1..100000).to_a
    end
  end
end





describe "Indexer State" do

  it "can blah" do
    AppConfig[:data_directory] = '/tmp'

    @state = IndexState.new

    @state.all_ids(1, 'archival_object', Time.now).should eq([1,2,3])

  end
end
