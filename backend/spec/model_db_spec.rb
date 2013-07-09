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

end
