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
    expect(@parent.position).to eq(0)

    expect([@child1, @child2, @child3].map {|record| record.position}).to eq([0, 1, 2])
  end



  it "updates an object without affecting its position" do
    ArchivalObject[@child1.id].update_from_json(@child1)

    refresh!

    expect([@child1, @child2, @child3].sort_by(&:position)).to eq([@child1, @child2, @child3])
  end


  it "can change the position of an object by updating it" do
    @child1.position = 2

    ArchivalObject[@child1.id].update_from_json(@child1)

    refresh!

    expect([@child1, @child2, @child3].sort_by(&:position)).to eq([@child2, @child3, @child1])
  end


  it "leaves us where we started if we repeatedly move the first to the last" do
    @child1.position = 2; ArchivalObject[@child1.id].update_from_json(@child1)
    @child2.position = 2; ArchivalObject[@child2.id].update_from_json(@child2)
    @child3.position = 2; ArchivalObject[@child3.id].update_from_json(@child3)

    refresh!

    expect([@child1, @child2, @child3].sort_by(&:position)).to eq([@child1, @child2, @child3])

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

    expect([@child1, @child2, @child3].sort_by(&:position)).to eq([@child3, @child2, @child1])
  end


  it 'handles logical and physical positions without a database constraint violation' do
    # The following test verifies a fix to the handling of archival object
    # physical and logical positions, such that a database constraint violation
    # does not occur.
    #
    # The 'UNIQ_AO_POS' index defined on 'ARCHIVAL_OBJECT' requires that the
    # "parent name" and "position" fields be unique. Prior to the fix, this
    # constraint could be violated when updating a record. The violation
    # occurred because the archival object was updated with the
    # logical position set for the "position" field, instead of the physical
    # position. In a situation where there are a large number of records,
    # the logical position of a record may overlap with the physical position
    # of an earlier record, leading to the constraint violation.
    #
    # In the following test, the TreeNodes::POSITION_STEP is reduced to 10,
    # so only 10 child objects needs to be created to demonstrate the problem,
    # instead of 1000 child objects.

    # Reset the TreeNodes::POSITION_STEP, storing the old value.
    original_position_step = TreeNodes::POSITION_STEP

    TreeNodes::POSITION_STEP = 10

    # Create a "TreeNodes::POSITION_STEP" number of child archival objects.
    # The first child should have a "physical position" equal to
    # "TreeNodes::POSITION_STEP", while the last child should have a
    # "logical position" equal to "TreeNodes::POSITION_STEP"
    resource = create(:json_resource)

    parent = create(:json_archival_object,
                    resource: { 'ref' => resource.uri },
                    title: 'Parent')

    num_children = TreeNodes::POSITION_STEP
    children = []
    (0..num_children).each do |i|
      child = create(:json_archival_object,
                     resource: { 'ref' => resource.uri },
                     parent: { 'ref' => parent.uri },
                     title: "Child #{i}")
      children << child
    end

    # Verify that the "physical position" of the first child is equal
    # to the "logical position" of the last child. This is necessary in
    # order for the constraint to be violated.
    first_child = children.first
    last_child = children.last

    first_ao = ArchivalObject[first_child.id]
    last_ao = ArchivalObject[last_child.id]
    expect(first_ao.position).to eq(last_ao.logical_position)

    # Store physical position of last archival object, so we can check it later
    # to make sure it hasn't changed.
    last_ao_position = last_ao.position

    begin
      # Attempt to update the last child. This will throw a constraint violation
      # exception if the logical position is used when updating the archival
      # object in the database.
      ArchivalObject[last_child.id].update_from_json(last_child)
    ensure
      # Reset the TreeNodes::POSITION_STEP for any other tests
      TreeNodes::POSITION_STEP = original_position_step
    end

    # Physical position of last archival object should not have changed.
    last_ao.refresh
    expect(last_ao.position).to eq(last_ao_position)
  end

  it 'updating an element should not change its physical position' do
    # Store physical position of child1 object, so we can check it later
    # to make sure it hasn't changed.
    child1_ao = ArchivalObject[@child1.id]
    child1_physical_position = child1_ao.position

    # Update the child.
    child1_ao.update_from_json(@child1)

    # Physical position of the child should not have changed.
    child1_ao.refresh
    expect(child1_ao.position).to eq(child1_physical_position)
  end

end
