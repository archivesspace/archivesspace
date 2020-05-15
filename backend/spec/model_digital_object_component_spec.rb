require 'spec_helper'
require 'securerandom'
require_relative 'spec_slugs_helper'

describe 'DigitalObjectComponent model' do

  it "Allows digital object components to be created" do
    doc = create(:json_digital_object_component_unpub_ancestor)
    bib_note = build(:json_note_bibliography)
    do_note = build(:json_note_digital_object)
    doc.notes = [bib_note, do_note]
    expect(DigitalObjectComponent[doc.id].title).to eq(doc.title)
  end

  it "auto generates a 'label' based on the date and title when both are present" do
    title = "Just a title"
    date1 = build(:json_date, :date_type => 'inclusive')
    date2 = build(:json_date, :date_type => 'bulk')

    doc = DigitalObjectComponent.create_from_json(
      build(:json_digital_object_component, {
        :title => title,
        :dates => [date1, date2]
      }),
      :repo_id => $repo_id)

    expect(DigitalObjectComponent[doc[:id]].display_string).to eq("#{title}, #{date1['expression']}, #{I18n.t("date_type_bulk.bulk")}: #{date2['expression']}")
  end

  describe "slug tests" do
    before(:all) do
      AppConfig[:use_human_readable_urls] = true
    end

    describe "slug autogen enabled" do
      describe "by name" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = false
        end
        it "autogenerates a slug via title" do
          digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true, :title => rand(100000).to_s))
          expected_slug = clean_slug(digital_object_component[:title])
          expect(digital_object_component[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true, :title => "Foo Bar Baz&&&&"))
          expect(digital_object_component[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          digital_object_component1 = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true, :title => "foo"))
          digital_object_component2 = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true, :title => "foo"))
          expect(digital_object_component1[:slug]).to eq("foo")
          expect(digital_object_component2[:slug]).to eq("foo_1")
        end
        it "turns off autogen if slug is blank" do
          digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true))
          digital_object_component.update(:slug => "")
          expect(digital_object_component[:is_slug_auto]).to eq(0)
        end
      end
      describe "by id" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = true
        end
        it "autogenerates a slug via identifier" do
          digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true))
          expected_slug = clean_slug(digital_object_component[:component_id])
          expect(digital_object_component[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true, :component_id => "Foo Bar Baz&&&&"))
          expect(digital_object_component[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          digital_object_component1 = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true, :component_id => "foo"))
          digital_object_component2 = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => true, :component_id => "foo#"))
          expect(digital_object_component1[:slug]).to eq("foo")
          expect(digital_object_component2[:slug]).to eq("foo_1")
        end
      end
    end

    describe "slug autogen disabled" do
      before(:all) do
        AppConfig[:auto_generate_slugs_with_id] = false
      end
      it "slug does not change when config set to autogen by title and title updated" do
        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => false, :slug => "foo"))
        digital_object_component.update(:title => rand(100000000))
        expect(digital_object_component[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => false, :slug => "foo"))
        digital_object_component.update(:component_id => rand(100000000))
        expect(digital_object_component[:slug]).to eq("foo")
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => false))
        digital_object_component.update(:slug => "Foo Bar Baz ###")
        expect(digital_object_component[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        digital_object_component1 = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => false, :slug => "foo"))
        digital_object_component2 = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :is_slug_auto => false))

        digital_object_component2.update(:slug => "foo")

        expect(digital_object_component1[:slug]).to eq("foo")
        expect(digital_object_component2[:slug]).to eq("foo_1")
      end
    end
  end
end
