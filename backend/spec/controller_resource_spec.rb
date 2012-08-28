require 'spec_helper'

describe 'Resources controller' do

  before(:each) do
    make_test_repo
  end


  it "lets you create a resource and get it back" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123")
    id = resource.save

    JSONModel(:resource).find(id).title.should eq("a resource")
  end


  it "lets you manipulate the record hierarchy" do

    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123")
    id = resource.save

    aos = []
    ["earth", "australia", "canberra"].each do |name|
      ao = JSONModel(:archival_object).from_hash("ref_id" => name,
                                                 "title" => "archival object: #{name}")
      if not aos.empty?
        ao.parent = aos.last.uri
      end

      ao.resource = resource.uri
      ao.save
      aos << ao
    end

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

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

    JSONModel(:resource_tree).from_hash(changed).save(:resource_id => resource.id)
    changed.delete("uri")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.to_hash.should eq(changed)
  end



  it "lets you update a resource" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123")
    id = resource.save

    resource.title = "an updated resource"
    resource.save

    JSONModel(:resource).find(id).title.should eq("an updated resource")
  end


  it "can handle asking for the tree of an empty resource" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123")
    id = resource.save

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.should eq(nil)
  end


  it "adds an archival object to a resource when it's added to the tree" do
    ao = JSONModel(:archival_object).from_hash("ref_id" => "testing123",
                                               "title" => "archival object")
    ao_id = ao.save


    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123")
    coll_id = resource.save


    tree = JSONModel(:resource_tree).from_hash(:archival_object => ao.uri,
                                                 :children => [])

    tree.save(:resource_id => coll_id)

    JSONModel(:archival_object).find(ao_id).resource == "#{@repo}/resources/#{coll_id}"
  end


  it "lets you create a resource with a subject" do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Some Vocab", 
                                             "ref_id" => "abc"
                                            )
    vocab.save
    vocab_uri = JSONModel(:vocabulary).uri_for(vocab.id)
    subject = JSONModel(:subject).from_hash("terms"=>[{"term" => "a test subject", "term_type" => "Cultural context", "vocabulary" => vocab_uri}],
                                            "vocabulary" => vocab_uri
                                            )
    subject.save

    resource = JSONModel(:resource).from_hash("title" => "a resource", 
                                                  "id_0" => "abc123",
                                                  "subjects" => [subject.uri]
                                                 )
    coll_id = resource.save

    JSONModel(:resource).find(coll_id).subjects[0].should eq(subject.uri)
  end


end
