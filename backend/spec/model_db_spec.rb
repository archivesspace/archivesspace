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

    expect(attempt).to eq(5)
  end

  it "Retries transactions on NoExistingObject/OptimisticLocking exception if told to retry on optimistic locking fail" do

    attempt = 0

    expect {
      transaction = true
      DB.open( transaction, :retry_delay => 0 ) do
        attempt += 1
        raise Sequel::Plugins::OptimisticLocking::Error.new("Couldn't create version of blah")
      end
    }.to raise_error(Sequel::NoExistingObject)

    # the default it 10
    expect(attempt).to eq(1)
    attempt = 0

    expect {
      transaction = true
      DB.open( transaction, :retry_on_optimistic_locking_fail => true, :retry_delay => 0 ) do
        attempt += 1
        raise Sequel::Plugins::OptimisticLocking::Error.new("Couldn't create version of blah")
      end
    }.to raise_error(Sequel::NoExistingObject)

    # the default it 10
    expect(attempt).to eq(10)
  end

  it "Fails with a helpful message if no database has been configured" do
    [nil, '', '   '].each do |db_url|
      expect {
        DB.check_configured(db_url)
      }.to raise_error(/Database not configured/)
    end
  end

  it "Accepts a configured database url" do
    expect(DB.check_configured(AppConfig[:db_url])).to be_nil
  end

  it "Only supports MySQL" do
    expect(DB.check_supported(AppConfig[:db_url])).to be_nil

    expect {
      DB.check_supported('jdbc:derby:memory:archivesspace_demo_db;create=true')
    }.to raise_error(/Database not supported/)
  end

end
