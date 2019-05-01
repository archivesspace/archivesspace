require 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Classification models' do

  let(:creator) { create(:json_agent_person) }
  let(:classification) { create_classification }
  let(:resource) { create(:json_resource) }

  def create_classification
    classification = build(:json_classification,
                           :title => "top-level classification",
                           :identifier => "abcdef",
                           :description => "A classification",
                           :creator => {'ref' => creator.uri},
                          :linked_records => [ 'ref' => resource.uri ])

    Classification.create_from_json(classification)
  end


  def create_classification_term(parent, properties = {})
    term = build(:json_classification_term,
                 {
                   :title => "classification A",
                   :identifier => "class-a",
                   :description => "classification A",
                   :classification => {'ref' => parent.uri},
                   :creator => {'ref' => creator.uri}
                 }.merge(properties))

    ClassificationTerm.create_from_json(term)
  end


  it "allows a classification to be created" do
    expect(classification.title).to eq("top-level classification")
    expect(Classification.to_jsonmodel(classification)['creator']['ref']).to eq(creator.uri)
  end


  it "allows a tree of classification_terms to be created" do
    term = create_classification_term(classification)
    expect(term.title).to eq("classification A")

    expect(classification.tree['children'].count).to eq(1)
    expect(classification.tree['children'].first['title']).to eq(term.title)
    expect(classification.tree['children'].first['record_uri']).to eq(term.uri)

    second_term = create_classification_term(classification,
                                             :title => "child of the last term",
                                             :identifier => "another",
                                             :parent => {'ref' => term.uri})

    expect(classification.tree['children'][0]['children'][0]['title']).to eq(second_term.title)
  end


  it "enforces title uniqueness at the same level in the tree" do
    create_classification_term(classification, :title => "never duplicated")

    expect {
      create_classification_term(classification, :title => "never duplicated")
    }.to raise_error(Sequel::ValidationFailed)
  end


  it "enforces identifier uniqueness at the same level in the tree" do
    create_classification_term(classification,
                               :title => "different titles",
                               :identifier => "same IDs")

    expect {
      create_classification_term(classification,
                                 :title => "yes!  totally different!",
                                 :identifier => "same IDs")
    }.to raise_error(Sequel::ValidationFailed)
  end


  it "doesn't mind if you reuse identifiers or titles at different levels" do
    term1 = create_classification_term(classification,
                                       :title => "same titles",
                                       :identifier => "same IDs")

    expect {
      create_classification_term(classification,
                                 :title => "same titles",
                                 :identifier => "same IDs",
                                 :parent => {'ref' => term1.uri})
    }.not_to raise_error
  end


  it "can delete a classification tree" do
    term1 = create_classification_term(classification,
                                       :title => "same titles",
                                       :identifier => "same IDs")

    term2 = create_classification_term(classification,
                                       :title => "same titles",
                                       :identifier => "same IDs",
                                       :parent => {'ref' => term1.uri})


    expect {
      classification.delete
    }.not_to raise_error

    expect { term1.refresh }.to raise_error(Sequel::Error)
    expect { term2.refresh }.to raise_error(Sequel::Error)
  end


  it "can reorder classification terms" do
    terms = []
    5.times do |i|
      terms << create_classification_term(classification,
                                          :title => "title #{i}",
                                          :identifier => "id#{i}")
    end

    terms.last.set_parent_and_position(terms.last.parent_id, 0)

    titles = classification.tree['children'].map {|e| e['title']}

    expect(titles).to eq(["title 4", "title 0", "title 1", "title 2", "title 3"])
  end


  it "includes a path from the root node" do
    term1 = create_classification_term(classification,
                                       :title => "same titles",
                                       :identifier => "same IDs")

    term2 = create_classification_term(classification,
                                       :title => "same titles",
                                       :identifier => "same IDs",
                                       :parent => {'ref' => term1.uri})

    titles = ClassificationTerm.to_jsonmodel(term2)['path_from_root'].map {|e| e['title']}

    expect(titles).to eq(["top-level classification", "same titles", "same titles"])
  end


  it "includes references to linked archival records" do
    term = create_classification_term(classification)

    resource = create(:json_resource,
                      :classifications => [
                                           {'ref' => classification.uri},
                                           {'ref' => term.uri}
                                           ])

    expect(JSONModel(:classification).find(classification.id).linked_records.map {|link| link['ref'] }).to include(resource.uri)

    expect(JSONModel(:classification_term).find(term.id).linked_records.map {|link| link['ref'] }).to include(resource.uri)

  end

  describe "slug tests" do
    before(:all) do
      AppConfig[:use_human_readable_URLs] = true
    end

    describe "slug autogen enabled" do
      describe "by name" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = false
        end
        it "autogenerates a slug via title" do
          classification = Classification.create_from_json(build(:json_classification, :is_slug_auto => true, :title => rand(100000).to_s))
          expected_slug = clean_slug(classification[:title])
          expect(classification[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          classification = Classification.create_from_json(build(:json_classification, :is_slug_auto => true, :title => "Foo Bar Baz&&&&"))
          expect(classification[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          classification1 = Classification.create_from_json(build(:json_classification, :is_slug_auto => true, :title => "foo"))
          classification2 = Classification.create_from_json(build(:json_classification, :is_slug_auto => true, :title => "foo"))
          expect(classification1[:slug]).to eq("foo")
          expect(classification2[:slug]).to eq("foo_1")
        end
        it "turns off autogen if slug is blank" do
          classification = Classification.create_from_json(build(:json_classification, :is_slug_auto => true))
          classification.update(:slug => "")
          expect(classification[:is_slug_auto]).to eq(0)
        end
      end
      describe "by id" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = true
        end
        it "autogenerates a slug via identifier" do
          classification = Classification.create_from_json(build(:json_classification, :is_slug_auto => true))
          expected_slug = clean_slug(classification[:identifier])
          expect(classification[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          classification = Classification.create_from_json(build(:json_classification, :is_slug_auto => true, :identifier => "Foo Bar Baz&&&&"))
          expect(classification[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          classification1 = Classification.create_from_json(build(:json_classification, :is_slug_auto => true, :identifier => "foo"))
          classification2 = Classification.create_from_json(build(:json_classification, :is_slug_auto => true, :identifier => "foo#"))
          expect(classification1[:slug]).to eq("foo")
          expect(classification2[:slug]).to eq("foo_1")
        end
      end
    end

    describe "slug autogen disabled" do
      before(:all) do
        AppConfig[:auto_generate_slugs_with_id] = false
      end
      it "slug does not change when config set to autogen by title and title updated" do
        classification = Classification.create_from_json(build(:json_classification, :is_slug_auto => false, :slug => "foo"))
        classification.update(:title => rand(100000000))
        expect(classification[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        classification = Classification.create_from_json(build(:json_classification, :is_slug_auto => false, :slug => "foo"))
        classification.update(:identifier => rand(100000000))
        expect(classification[:slug]).to eq("foo")
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        classification = Classification.create_from_json(build(:json_classification, :is_slug_auto => false))
        classification.update(:slug => "Foo Bar Baz ###")

        expect(classification[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        classification1 = Classification.create_from_json(build(:json_classification, :is_slug_auto => false, :slug => "foo"))
        classification2 = Classification.create_from_json(build(:json_classification, :is_slug_auto => false))

        classification2.update(:slug => "foo")

        expect(classification1[:slug]).to eq("foo")
        expect(classification2[:slug]).to eq("foo_1")
      end
    end
  end
end
