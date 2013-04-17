require 'spec_helper'

describe 'Sequence model' do

  it "Allows sequences to be retrieved" do
    Sequence.get("new_sequence").should eq(0)
    Sequence.get("new_sequence").should eq(1)
  end


  it "Lets you initialise a sequence to a number" do
    Sequence.init("another_sequence", 5)
    Sequence.get("another_sequence").should eq(6)
  end


  it "Doesn't suffer obvious concurrency issues" do
    test_threads = 2

    threads = (0...test_threads).map {|i|
      Thread.new do
        numbers = []
        100.times do
          numbers << Sequence.get("concurrent_sequence")
        end

        numbers
      end
    }

    # Wow.  Take that, LawOfDemeter!
    threads.map {|thread| thread.value}.flatten.uniq.count.should eq(test_threads * 100)
  end

end
