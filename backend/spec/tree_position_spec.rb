require 'spec_helper'

describe 'Tree positioning' do

  before(:each) do
    @resource = create(:json_resource)

    @parent = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :title => "Parent")

    @child1 = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :parent => {'ref' => @parent.uri},
                     :title => "Child 1")

    @child2 = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :parent => {'ref' => @parent.uri},
                     :title => "Child 2")

    @child3 = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :parent => {'ref' => @parent.uri},
                     :title => "Child 3")
  end


  def refresh!
    [:@parent, :@child1, :@child2, :@child3].each do |var|
      new_obj = ArchivalObject.to_jsonmodel(instance_variable_get(var).id)
      instance_variable_set(var, new_obj)
    end
  end


  it "gives a sensible initial ordering" do
    @parent.position.should eq(0)

    [@child1, @child2, @child3].map {|record| record.position}.should eq([0, 1, 2])
  end



  it "updates an object without affecting its position" do
    ArchivalObject[@child1.id].update_from_json(@child1)

    refresh!

    [@child1, @child2, @child3].sort_by(&:position).should eq([@child1, @child2, @child3])
  end


  it "can change the position of an object by updating it" do
    @child1.position = 2

    ArchivalObject[@child1.id].update_from_json(@child1)

    refresh!

    [@child1, @child2, @child3].sort_by(&:position).should eq([@child2, @child3, @child1])
  end


  it "leaves us where we started if we repeatedly move the first to the last" do
    @child1.position = 2; ArchivalObject[@child1.id].update_from_json(@child1)
    @child2.position = 2; ArchivalObject[@child2.id].update_from_json(@child2)
    @child3.position = 2; ArchivalObject[@child3.id].update_from_json(@child3)

    refresh!

    [@child1, @child2, @child3].sort_by(&:position).should eq([@child1, @child2, @child3])

  end


  it "can swap two elements after some shuffling around" do
    # I think this is where things are currently going wrong...

    @child1.position = 2; ArchivalObject[@child1.id].update_from_json(@child1)
    @child2.position = 2; ArchivalObject[@child2.id].update_from_json(@child2)
    @child3.position = 2; ArchivalObject[@child3.id].update_from_json(@child3)

    refresh!

    # Swap child1 and child3 by assigning their positions.
    #
    # Previously this case could fail because the positions in the database
    # might contain gaps.  For example, at the end of the first shuffle, the
    # positions of our three records could be something like:
    #
    #  [3, 5, 10]
    #
    # That's all fine as far as the database schema is concerned, since it only
    # cares that these numbers will result in the correct ordering when sorted.
    #
    # However, things go wrong when we take this position, load it into a
    # JSONModel and expose it through the API.  The API and frontend work with
    # logical positions, where setting a record to position = 2 always means
    # "this is the third item in the list".  If the frontend takes the second
    # record (with a position of '5' in the DB) and updates it, it passes
    # 'position = 5' back through to the backend.  The backend then assumes this
    # '5' is an logical '5', so it adjusts it to be relative to the other
    # numbers it has.  Since it appears that the frontend wanted the second
    # record to be moved to position 5, and since there are only three records,
    # it moves the record to the end of the list.
    #
    # So in short, it's a confusion between two different numbering systems.  Or
    # if you like Dr Seuss, it's the Goose drinking Moose Juice and vice versa.


    tmp = @child1.position
    @child1.position = @child3.position
    @child3.position = tmp

    ArchivalObject[@child1.id].update_from_json(@child1)
    ArchivalObject[@child3.id].update_from_json(@child3)

    refresh!

    [@child1, @child2, @child3].sort_by(&:position).should eq([@child3, @child2, @child1])
  end



end
