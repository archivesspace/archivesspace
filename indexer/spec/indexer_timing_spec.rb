require_relative 'spec_helper'
require_relative '../app/lib/indexer_timing'

describe "indexer timing" do
  before(:each) do
    @it = IndexerTiming.new
  end

  describe "initialize" do
    it "initializes metrics instance variable to empty hash" do
      expect(@it.instance_variable_get(:@metrics)).to eq({})
    end
  end
  describe "add" do
    it "starts metrics[metric] value at 0 if metrics[metric] does not exist" do
      @it.add("metric",6)
      expect(@it.instance_variable_get(:@metrics)).to eq({"metric"=>6})
    end
    it "adds values in the metrics hash" do
      @it.add("metric",12)
      expect(@it.instance_variable_get(:@metrics)).to eq({"metric"=>12})
      @it.add("metric",6)
      expect(@it.instance_variable_get(:@metrics)).to eq({"metric"=>18})
    end
  end
  describe "to_s" do
    describe "@total does not exist" do
      it "reports indexer timing subtotal as a string" do
        expect(@it.instance_variable_get(:@total)).to be_nil
        @it.add("metric",12)
        expect(@it.to_s).to eq("12 ms (metric: 12)")
      end
    end
    describe "@total does exist" do
      it "reports indexer timing total as a string including description of other metrics" do
        @it.instance_variable_set(:@total,100)
        @it.add("metric",12)
        expect(@it.to_s).to eq("100 ms (metric: 12; other: 88)")
      end
    end
  end
  describe "total=" do
    it "sets total to given value" do
      expect(@it.instance_variable_get(:@total)).to be_nil
      @it.total=(99)
      expect(@it.instance_variable_get(:@total)).to eq(99)
    end
  end
  describe "time_block" do
    it "computes a time block" do
      @it.add("metric",0)
      sleep_time = 15
      @it.time_block("metric") { sleep sleep_time }
      metrics = @it.instance_variable_get(:@metrics)
      expect(metrics["metric"].to_i).to be_within(10).of(sleep_time * 1000)
    end
  end
end
