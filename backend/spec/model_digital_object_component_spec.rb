require 'spec_helper'
require 'securerandom'

describe 'DigitalObjectComponent model' do

  it "Allows digital object components to be created" do
    doc = create(:json_digital_object_component,
                 {
                   :title => "A new digital object component"
                 })

    DigitalObjectComponent[doc.id].title.should eq("A new digital object component")
  end

end
