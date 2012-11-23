require 'spec_helper'


describe 'Collection Management Record controller' do

  it "paginates record listings" do
    10.times { create(:json_collection_management) }

    page1_ids = JSONModel(:collection_management).all(:page => 1, :page_size => 5)['results'].map {|obj| obj.id}
    page2_ids = JSONModel(:collection_management).all(:page => 2, :page_size => 5)['results'].map {|obj| obj.id}

    page1_ids.length.should eq(5)
    page2_ids.length.should eq(5)

    # No overlaps between the contents of our two pages
    (page1_ids - page2_ids).length.should eq(5)
  end

end
