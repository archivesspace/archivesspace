require 'spec_helper'

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

    Subject[subject[:id]].term[0].id.should eq(term_id)
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

    Subject[subject[:id]].term[0].id.should eq(term_id_0)
    Subject[subject[:id]].term[1].id.should eq(term_id_1)
    Subject[subject[:id]].term[2].id.should eq(term_id_2)
    Subject[subject[:id]].term[3].id.should eq(term_id_3)
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
    vocab = create(:json_vocab)
    heading_id = "12aBCD12"
    subject_a = create(:json_subject, {:vocabulary => vocab.uri, :source => "local", :authority_id => heading_id})

    expect {
      create(:json_subject, {:vocabulary => vocab.uri})
    }.to_not raise_error

    expect {
      create(:json_subject, {:vocabulary => vocab.uri, :source => "local", :authority_id => heading_id})
    }.to raise_error(JSONModel::ValidationException)

  end



  it "allows authority ids to have spaces and funny characters" do
    vocab = create(:json_vocab)
    
    expect {
      create(:json_subject, {:vocabulary => vocab.uri, :source => "local", :authority_id => "H0w N0w Br0wn C9w"})
    }.to_not raise_error

    expect {
      create(:json_subject, {:vocabulary => vocab.uri, :source => "local", :authority_id => " Ke$ha!!"})
    }.to_not raise_error

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

    Subject[subject[:id]].title.should eq("#{term_id_0.term} -- #{term_id_1.term}")
  end


  it "can merge one subject into another" do
    victim_subject = Subject.create_from_json(build(:json_subject))
    target_subject = Subject.create_from_json(build(:json_subject))

    # A record that uses the victim subject
    acc = create(:json_accession, 'subjects' => [{'ref' => victim_subject.uri}])

    target_subject.assimilate([victim_subject])

    JSONModel(:accession).find(acc.id).subjects[0]['ref'].should eq(target_subject.uri)

    victim_subject.exists?.should be(false)
  end


  it "can derive a subject's publication status from those of its associates" do
    subject = create(:json_subject)
    JSONModel(:subject).find(subject.id).is_linked_to_published_record.should be(false)


    acc = create(:json_accession, 'subjects' => [{'ref' => subject.uri}], 'publish' => true)
    JSONModel(:subject).find(subject.id).is_linked_to_published_record.should be(true)

    acc.publish = false
    acc.save
    JSONModel(:subject).find(subject.id).is_linked_to_published_record.should be(false)
  end
end
