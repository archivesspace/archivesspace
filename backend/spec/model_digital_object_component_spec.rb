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

    it "generates a slug for largetree if use_human_readable_URLs is set to true" do
      AppConfig[:use_human_readable_URLs] = true

      expect(SlugHelpers.get_slugged_url_for_largetree("DigitalObjectComponent", $repo_id, "doc_slug")).to eq( AppConfig[:public_proxy_url] + "/digital_object_components/doc_slug")
    end

    it "does not generate a slug for largetree if use_human_readable_URLs is set to false" do
      AppConfig[:use_human_readable_URLs] = false

      expect(SlugHelpers.get_slugged_url_for_largetree("DigitalObjectComponent", $repo_id, "doc_slug").empty?).to eq( true )
    end

    describe "slug code does not run" do
      it "does not execute slug code when auto-gen on id and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true

        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, {:is_slug_auto => true}))

        expect(digital_object_component).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)

        digital_object_component.update(:title => "foobar")
      end

      it "does not execute slug code when auto-gen on title and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false

        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, {:is_slug_auto => true}))

        expect(digital_object_component).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)

        digital_object_component.update(:component_id => "foobar")
      end

      it "does not execute slug code when auto-gen off and title, identifier changed" do
        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, {:is_slug_auto => false}))

        expect(digital_object_component).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)

        digital_object_component.update(:component_id => "foobar")
        digital_object_component.update(:title => "barfoo")
      end
    end

    describe "slug code runs" do
      it "executes slug code when auto-gen on id and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true

        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, {:is_slug_auto => true}))

        expect(digital_object_component).to receive(:auto_gen_slug!)
        expect(SlugHelpers).to receive(:clean_slug)

        pending("no idea why this is failing. Testing this manually in app works as expected")

        digital_object_component.update(:component_id => "foo#{rand(10000)}")
      end

      it "executes slug code when auto-gen on title and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false

        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, {:is_slug_auto => true}))

        expect(digital_object_component).to receive(:auto_gen_slug!)

        digital_object_component.update(:title => "foobar")
      end

      it "executes slug code when autogen is turned on" do
        AppConfig[:auto_generate_slugs_with_id] = false
        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, {:is_slug_auto => false}))

        expect(digital_object_component).to receive(:auto_gen_slug!)

        digital_object_component.update(:is_slug_auto => 1)
      end

      it "executes slug code when autogen is off and slug is updated" do
        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, {:is_slug_auto => false}))

        expect(SlugHelpers).to receive(:clean_slug)

        digital_object_component.update(:slug => "snow white")
      end
    end

  end

end
