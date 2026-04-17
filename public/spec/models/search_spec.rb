require 'spec_helper'

describe "Search model" do

  it "doesn't allow concurrency to overpopulate Boolean Opts" do
    threads = []
    5.times do
      threads << Thread.new do
        Search.get_boolean_opts
      end
    end
    threads.map(&:join)
    boolean_opts = Search.get_boolean_opts
    boolean_opts.reject! {|opt| opt.nil?}
    entries = boolean_opts.map {|pair| pair[0] }
    expect(entries).to eq entries.uniq
  end
end
