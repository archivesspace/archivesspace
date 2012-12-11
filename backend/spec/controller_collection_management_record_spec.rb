require 'spec_helper'


describe 'Collection Management Record controller' do

  it "can create a collection management record" do
    digital_object = create(:json_digital_object)

    cm = create(:json_collection_management, :linked_records => [{:ref => digital_object.uri, :other_junk => "dropped"}])

    cm.should_not be(nil)
  end

end
