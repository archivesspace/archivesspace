require 'spec_helper'
require 'securerandom'

describe 'DigitalObjectComponent model' do

  it "Allows digital object components to be created" do
    doc = create(:json_digital_object_component_unpub_ancestor)
    bib_note = build(:json_note_bibliography)
    do_note = build(:json_note_digital_object)
    doc.notes = [bib_note, do_note]
    DigitalObjectComponent[doc.id].title.should eq(doc.title)
  end

end
