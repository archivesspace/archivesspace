require 'spec_helper'

describe 'Sequence model' do

  it "Allows sequences to be retrieved" do
    expect(Sequence.get("new_sequence")).to eq(0)
    expect(Sequence.get("new_sequence")).to eq(1)
  end


  it "Lets you initialise a sequence to a number" do
    Sequence.init("another_sequence", 5)
    expect(Sequence.get("another_sequence")).to eq(6)
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
    expect(threads.map {|thread| thread.value}.flatten.uniq.count).to eq(test_threads * 100)
  end

end
