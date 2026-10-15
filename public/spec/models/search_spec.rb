require 'spec_helper'

describe "Search model" do

  describe ".normalize_sort" do
    it "restores the space stripped from a title sort" do
      expect(Search.normalize_sort('title_sortasc')).to eq('title_sort asc')
      expect(Search.normalize_sort('title_sortdesc')).to eq('title_sort desc')
    end

    it "leaves an already valid sort spec alone" do
      expect(Search.normalize_sort('title_sort asc')).to eq('title_sort asc')
      expect(Search.normalize_sort('top_container_u_icusort asc')).to eq('top_container_u_icusort asc')
    end

    it "treats a form-encoded plus as a space" do
      expect(Search.normalize_sort('title_sort+asc')).to eq('title_sort asc')
    end

    it "leaves blank and unrelated values alone" do
      expect(Search.normalize_sort(nil)).to be_nil
      expect(Search.normalize_sort('')).to eq('')
    end
  end

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
