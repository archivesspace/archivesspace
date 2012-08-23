require 'spec_helper'

describe 'Collections controller' do

  before(:each) do
    make_test_repo
  end


  it "lets you create a collection and get it back" do
    collection = JSONModel(:collection).from_hash("title" => "a collection", "id_0" => "abc123")
    id = collection.save

    JSONModel(:collection).find(id).title.should eq("a collection")
  end


  it "lets you manipulate the record hierarchy" do

    collection = JSONModel(:collection).from_hash("title" => "a collection", "id_0" => "abc123")
    id = collection.save

    aos = []
    ["earth", "australia", "canberra"].each do |name|
      ao = JSONModel(:archival_object).from_hash("ref_id" => name,
                                                 "title" => "archival object: #{name}")
      if not aos.empty?
        ao.parent = aos.last.uri
      end

      ao.collection = collection.uri
      ao.save
      aos << ao
    end

    tree = JSONModel(:collection_tree).find(nil, :collection_id => collection.id)

    tree.to_hash.should eq({
                     "archival_object" => aos[0].uri,
                     "title" => "archival object: earth",
                     "children" => [
                                    {
                                      "archival_object" => aos[1].uri,
                                      "title" => "archival object: australia",
                                      "children" => [
                                                     {
                                                       "archival_object" => aos[2].uri,
                                                       "title" => "archival object: canberra",
                                                       "children" => []
                                                     }
                                                    ]
                                    }
                                   ]
                   })


    # Now turn it on its head
    changed = {
      "archival_object" => aos[2].uri,
      "title" => "archival object: canberra",
      "children" => [
                     {
                       "archival_object" => aos[1].uri,
                       "title" => "archival object: australia",
                       "children" => [
                                      {
                                        "archival_object" => aos[0].uri,
                                        "title" => "archival object: earth",
                                        "children" => []
                                      }
                                     ]
                     }
                    ]
    }

    JSONModel(:collection_tree).from_hash(changed).save(:collection_id => collection.id)
    changed.delete("uri")

    tree = JSONModel(:collection_tree).find(nil, :collection_id => collection.id)

    tree.to_hash.should eq(changed)
  end



  it "lets you update a collection" do
    collection = JSONModel(:collection).from_hash("title" => "a collection", "id_0" => "abc123")
    id = collection.save

    collection.title = "an updated collection"
    collection.save

    JSONModel(:collection).find(id).title.should eq("an updated collection")
  end


  it "can handle asking for the tree of an empty collection" do
    collection = JSONModel(:collection).from_hash("title" => "a collection", "id_0" => "abc123")
    id = collection.save

    tree = JSONModel(:collection_tree).find(nil, :collection_id => collection.id)

    tree.should eq(nil)
  end


  it "adds an archival object to a collection when it's added to the tree" do
    ao = JSONModel(:archival_object).from_hash("ref_id" => "testing123",
                                               "title" => "archival object")
    ao_id = ao.save


    collection = JSONModel(:collection).from_hash("title" => "a collection", "id_0" => "abc123")
    coll_id = collection.save


    tree = JSONModel(:collection_tree).from_hash(:archival_object => ao.uri,
                                                 :children => [])

    tree.save(:collection_id => coll_id)

    JSONModel(:archival_object).find(ao_id).collection == "#{@repo}/collections/#{coll_id}"
  end


  it "lets you create a collection with a subject" do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Some Vocab", 
                                             "ref_id" => "abc"
                                            )
    vocab.save
    vocab_uri = JSONModel(:vocabulary).uri_for(vocab.id)
    subject = JSONModel(:subject).from_hash("terms"=>[{"term" => "a test subject", "term_type" => "Cultural context", "vocabulary" => vocab_uri}],
                                            "vocabulary" => vocab_uri
                                            )
    subject.save

    collection = JSONModel(:collection).from_hash("title" => "a collection", 
                                                  "id_0" => "abc123",
                                                  "subjects" => [subject.uri]
                                                 )
    coll_id = collection.save

    JSONModel(:collection).find(coll_id).subjects[0].should eq(subject.uri)
  end


end
