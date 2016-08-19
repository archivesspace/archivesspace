require 'spec_helper'

describe 'DB Model' do

  it "Retries transactions on retriable error" do
    attempt = 0

    expect {
      DB.open(true, :retry_delay => 0, :retries => 5) do
        attempt += 1
        raise RetryTransaction.new
      end
    }.to raise_error(RetryTransaction)

    attempt.should eq(5)
  end
  
  it "Retries transactions on NoExistingObject/OptimisticLocking exception if told to retry on optimistic locking fail" do

    attempt = 0
    
    expect {
      supports_mvcc = true
      DB.open( supports_mvcc,  :retry_delay => 0 ) do
        attempt += 1
        raise Sequel::Plugins::OptimisticLocking::Error.new("Couldn't create version of blah")
      end
    }.to raise_error(Sequel::NoExistingObject)

    # the default it 10
    attempt.should eq(1)
    attempt = 0

    expect {
      supports_mvcc = true
      DB.open( supports_mvcc, :retry_on_optimistic_locking_fail => true, :retry_delay => 0 ) do
        attempt += 1
        raise Sequel::Plugins::OptimisticLocking::Error.new("Couldn't create version of blah")
      end
    }.to raise_error(Sequel::NoExistingObject)

    # the default it 10
    attempt.should eq(10)
  end

end
