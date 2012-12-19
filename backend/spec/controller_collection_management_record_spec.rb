require 'spec_helper'


describe 'Collection Management Record controller' do

  it "can create a collection management record" do
    digital_object = create(:json_digital_object)

    cm = create(:json_collection_management, :linked_records => [{:ref => digital_object.uri, :other_junk => "dropped"}])

    cm.should_not be(nil)
  end


  it "can update a collection management record" do
    digital_object = create(:json_digital_object)
    cm = create(:json_collection_management, :linked_records => [{:ref => digital_object.uri, :other_junk => "dropped"}])
    cm.cataloged_note = "moo"
    cm.save

    JSONModel(:collection_management).find(cm.id).cataloged_note.should eq("moo")
  end


  it "returns a list of collection management records" do
    3.times {
      create(:json_collection_management)
    }
    JSONModel(:collection_management).all(:page => 1)["results"].size.should eq(3)
  end

end
