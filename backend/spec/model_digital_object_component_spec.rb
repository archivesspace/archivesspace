require 'spec_helper'
require 'securerandom'

describe 'DigitalObjectComponent model' do

  it "Allows digital object components to be created" do
    doc = create(:json_digital_object_component_unpub_ancestor)
    bib_note = build(:json_note_bibliography)
    do_note = build(:json_note_digital_object)
    doc.notes = [bib_note, do_note]
    expect(DigitalObjectComponent[doc.id].title).to eq(doc.title)
  end

  describe "slug tests" do
    it "autogenerates a slug via title when configured to generate by name" do
      AppConfig[:auto_generate_slugs_with_id] = false 

      digital_object = DigitalObjectComponent.create_from_json(build(:json_digital_object_component))
      

      digital_object_rec = DigitalObjectComponent.where(:id => digital_object[:id]).first.update(:is_slug_auto => 1)

      expected_slug = digital_object_rec[:title].gsub(" ", "_")
                                           .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")

      expect(digital_object_rec[:slug]).to eq(expected_slug)
    end

    it "autogenerates a slug via digital_object_id when configured to generate by id" do
      AppConfig[:auto_generate_slugs_with_id] = true

      digital_object = DigitalObjectComponent.create_from_json(build(:json_digital_object_component))
      

      digital_object_rec = DigitalObjectComponent.where(:id => digital_object[:id]).first.update(:is_slug_auto => 1)

      expected_slug = digital_object_rec[:component_id].gsub(" ", "_")
                                                .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")
                                                .gsub('"', '')
                                                .gsub('null', '')

      # numeric slugs will be prepended by an underscore
      if expected_slug =~ /^\d+$/
        expected_slug = "_#{expected_slug}"
      end

      expect(digital_object_rec[:slug]).to eq(expected_slug)
    end
  end

end
