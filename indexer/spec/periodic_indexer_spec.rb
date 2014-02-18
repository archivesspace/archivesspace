require_relative 'spec_helper'
require_relative '../app/lib/periodic_indexer'

describe "periodic indexer" do

  before(:all) do
    $now = Time.now.to_i

    $repos = []
    5.times {
      $repos << create(:json_repo).id
      create(:json_agent_family) # none generated on startup
    }

    JSONModel(:repository).class_eval do
      def self.all
       $repos.map {|id| self.find(id)}
      end
    end

    @pi = PeriodicIndexer.get_indexer

    @pi.instance_variable_get(:@state).instance_eval do
     def get_last_mtime(*args)
       $now
     end
   end
  end

 after(:all) do
   cleanup if defined? cleanup
 end

  it "indexes global records once" do
   $times_a_family_was_indexed = 0
   @pi.add_document_prepare_hook {|doc, record|
     if doc['primary_type'] == 'agent_family'
       $times_a_family_was_indexed += 1
     end
   }

   @pi.run_index_round 
   $times_a_family_was_indexed.should eq(5)
  end
end
