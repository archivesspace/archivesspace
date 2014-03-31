require 'spec_helper'

describe 'ArchivalObject notes mixin' do

  it "can publish subnotes" do
    subnote = build(:json_note_text, :content => "a text subnote", :publish => false)

    ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                               'notes' => [build(:json_note_multipart,
                                                                 'type' => 'accruals',
                                                                 :subnotes => [subnote])]))

    ao.publish!

    ArchivalObject.to_jsonmodel(ao.id)['notes'][0]['subnotes'][0]['publish'].should eq(true)
  end


  it "can delete a record with notes" do
    subnote = build(:json_note_text, :content => "a text subnote", :publish => false)

    ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                               'notes' => [build(:json_note_multipart,
                                                                 'type' => 'accruals',
                                                                 :subnotes => [subnote])]))

    ao.delete

    ArchivalObject[ao.id].should be(nil)
  end




  it "can unpublish subnotes" do
    subnote = build(:json_note_text, :content => "a text subnote", :publish => true)

    ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                               'notes' => [build(:json_note_multipart,
                                                                 'type' => 'accruals',
                                                                 :subnotes => [subnote])]))

    ao.unpublish!

    ArchivalObject.to_jsonmodel(ao.id)['notes'][0]['subnotes'][0]['publish'].should eq(false)
  end


end
