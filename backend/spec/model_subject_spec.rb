require 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Subject model' do

  def createTerm
    @count += 1
    Term.create_from_json(JSONModel(:term).
                          from_hash({
                                      'source' => 'local',
                                      "term" => "test#{Time.now.to_i}_#{@count}",
                                      "term_type" => "cultural_context",
                                      "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                    }))
  end


  before(:all) do
    @count = 0
  end

  before(:each) do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Cool Vocab",
                                             "ref_id" => "cool"
                                             )
    vocab.save
    @vocab_id = vocab.id
  end


  it "Allows a basic subject to be created" do
    term_id = createTerm.id
    subject = Subject.create_from_json(JSONModel(:subject).
                                       from_hash({
                                                    "source" => 'local',
                                                    "terms" => [
                                                               JSONModel(:term).uri_for(term_id)
                                                              ],
                                                   "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                 }))

    expect(Subject[subject[:id]].term[0].id).to eq(term_id)
  end


  it "Allows a subject with multiple terms to be created" do
    term_id_0 = createTerm.id
    term_id_1 = createTerm.id
    term_id_2 = createTerm.id
    term_id_3 = createTerm.id
    subject = Subject.create_from_json(JSONModel(:subject).
                                       from_hash({ 'source' => 'local',
                                                   "terms" => [
                                                               JSONModel(:term).uri_for(term_id_0),
                                                               JSONModel(:term).uri_for(term_id_1),
                                                               JSONModel(:term).uri_for(term_id_2),
                                                               JSONModel(:term).uri_for(term_id_3),
                                                              ],
                                                   "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                 }))

    expect(Subject[subject[:id]].term[0].id).to eq(term_id_0)
    expect(Subject[subject[:id]].term[1].id).to eq(term_id_1)
    expect(Subject[subject[:id]].term[2].id).to eq(term_id_2)
    expect(Subject[subject[:id]].term[3].id).to eq(term_id_3)
  end


  it "ensures unique subjects may only be created" do
    term_id_0 = createTerm.id
    term_id_1 = createTerm.id
    subject_a = Subject.create_from_json(JSONModel(:subject).
                                         from_hash({
                                                     "terms" => [
                                                       JSONModel(:term).uri_for(term_id_0),
                                                       JSONModel(:term).uri_for(term_id_1),
                                                     ],
                                                     "source" => "local",
                                                     "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                   }))
    expect {
       subject_b = Subject.create_from_json(JSONModel(:subject).
                                            from_hash({
                                                        "terms" => [
                                                          JSONModel(:term).uri_for(term_id_0),
                                                          JSONModel(:term).uri_for(term_id_1),
                                                        ],
                                                        "source" => "local",
                                                        "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                      }))
     }.to raise_error(Sequel::ValidationFailed)

  end

  it "ensures subject heading identifiers are unique within a source" do
    vocab = create(:json_vocabulary)
    heading_id = "12aBCD12"
    subject_a = create(:json_subject, {:vocabulary => vocab.uri, :source => "local", :authority_id => heading_id})

    expect {
      create(:json_subject, {:vocabulary => vocab.uri})
    }.not_to raise_error

    expect {
      create(:json_subject, {:vocabulary => vocab.uri, :source => "local", :authority_id => heading_id})
    }.to raise_error(JSONModel::ValidationException)

  end



  it "allows authority ids to have spaces and funny characters" do
    vocab = create(:json_vocabulary)

    expect {
      create(:json_subject, {:vocabulary => vocab.uri, :source => "local", :authority_id => "H0w N0w Br0wn C9w"})
    }.not_to raise_error

    expect {
      create(:json_subject, {:vocabulary => vocab.uri, :source => "local", :authority_id => " Ke$ha!!"})
    }.not_to raise_error

  end


  it "generates a subject title" do
    term_id_0 = createTerm
    term_id_1 = createTerm

    subject = Subject.create_from_json(JSONModel(:subject).
                                         from_hash({ 'source' => 'local',
                                                     "terms" => [
                                                       JSONModel(:term).uri_for(term_id_0.id),
                                                       JSONModel(:term).uri_for(term_id_1.id)
                                                     ],
                                                     "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                   }))

    #term_id_2 = createTerm

    expect(Subject[subject[:id]].title).to eq("#{term_id_0.term} -- #{term_id_1.term}")
  end


  it "can merge one subject into another" do
    merge_candidate_subject = Subject.create_from_json(build(:json_subject))
    merge_destination_subject = Subject.create_from_json(build(:json_subject))

    # A record that uses the merge_candidate subject
    acc = create(:json_accession, 'subjects' => [{'ref' => merge_candidate_subject.uri}])

    merge_destination_subject.assimilate([merge_candidate_subject])

    expect(JSONModel(:accession).find(acc.id).subjects[0]['ref']).to eq(merge_destination_subject.uri)

    expect(merge_candidate_subject.exists?).to be_falsey
  end


  it "can derive a subject's publication status from those of its associates" do
    subject = create(:json_subject)
    expect(JSONModel(:subject).find(subject.id).is_linked_to_published_record).to be_falsey


    acc = create(:json_accession, 'subjects' => [{'ref' => subject.uri}], 'publish' => true)
    expect(JSONModel(:subject).find(subject.id).is_linked_to_published_record).to be_truthy

    acc.publish = false
    acc.save
    expect(JSONModel(:subject).find(subject.id).is_linked_to_published_record).to be_falsey
  end

  it "can derive a subject's publication status from linked agents (subrecords)" do
    subject = create(:json_subject)
    expect(JSONModel(:subject).find(subject.id).is_linked_to_published_record).to be_falsey

    agent = create(:json_agent_person, 'agent_topics' => ['subjects' => [{'ref' => subject.uri}]], 'publish' => true)
    expect(agent['agent_topics'][0]['publish']).to be_truthy
    expect(JSONModel(:subject).find(subject.id).is_linked_to_published_record).to be_truthy

    agent.publish = false
    agent.save
    expect(agent['agent_topics'][0]['publish']).to be_falsey
    expect(JSONModel(:subject).find(subject.id).is_linked_to_published_record).to be_falsey
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
          subject = Subject.create_from_json(build(:json_subject, :is_slug_auto => true, :title => rand(100000).to_s))
          expected_slug = clean_slug(subject[:title])
          expect(subject[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          subject = Subject.create_from_json(build(:json_subject, :is_slug_auto => true, :title => "Foo Bar Baz&&&&"))
          expect(subject[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          subject1 = Subject.create_from_json(build(:json_subject, :is_slug_auto => true, :title => "foo"))
          subject2 = Subject.create_from_json(build(:json_subject, :is_slug_auto => true, :title => "foo"))
          expect(subject1[:slug]).to eq("foo")
          expect(subject2[:slug]).to eq("foo_1")
        end
        it "turns off autogen if slug is blank" do
          subject = Subject.create_from_json(build(:json_subject, :is_slug_auto => true))
          subject.update(:slug => "")
          expect(subject[:is_slug_auto]).to eq(0)
        end
      end
      describe "by id" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = true
        end
        it "autogenerates a slug via identifier" do
          subject = Subject.create_from_json(build(:json_subject, :is_slug_auto => true, :authority_id => rand(100000).to_s))
          expected_slug = clean_slug(subject[:authority_id])
          expect(subject[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          subject = Subject.create_from_json(build(:json_subject, :is_slug_auto => true, :authority_id => "Foo Bar Baz&&&&"))
          expect(subject[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          subject1 = Subject.create_from_json(build(:json_subject, :is_slug_auto => true, :authority_id => "foo"))
          subject2 = Subject.create_from_json(build(:json_subject, :is_slug_auto => true, :authority_id => "foo#"))
          expect(subject1[:slug]).to eq("foo")
          expect(subject2[:slug]).to eq("foo_1")
        end
      end
    end

    describe "slug autogen disabled" do
      before(:all) do
        AppConfig[:auto_generate_slugs_with_id] = false
      end
      it "slug does not change when config set to autogen by title and title updated" do
        subject = Subject.create_from_json(build(:json_subject, :is_slug_auto => false, :slug => "foo"))
        subject.update(:title => rand(100000000))
        expect(subject[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        subject = Subject.create_from_json(build(:json_subject, :is_slug_auto => false, :slug => "foo"))
        subject.update(:authority_id => rand(100000000))
        expect(subject[:slug]).to eq("foo")
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        subject = Subject.create_from_json(build(:json_subject, :is_slug_auto => false))
        subject.update(:slug => "Foo Bar Baz ###")
        expect(subject[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        subject1 = Subject.create_from_json(build(:json_subject, :is_slug_auto => false, :slug => "foo"))
        subject2 = Subject.create_from_json(build(:json_subject, :is_slug_auto => false))

        subject2.update(:slug => "foo")

        expect(subject1[:slug]).to eq("foo")
        expect(subject2[:slug]).to eq("foo_1")
      end
    end
  end
end
