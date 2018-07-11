require 'spec_helper'

describe 'Top Container model' do

  it "deletes all related instances and their subcontainers when top container is deleted" do

    # Create resource and link to instance
    resource = create(:json_resource,
                      :instances => [build(:json_instance)])

    # Identify top container
    top_container = ((resource['instances'][0]['sub_container']['top_container']['ref']).split('/'))[4].to_i
    linked_top_container = TopContainer.where(:id => top_container).first

    # Identify instance
    instance = linked_top_container.related_records(:top_container_link).map {|sub| Instance[sub.instance_id] }.first

    # Delete top container
    linked_top_container = JSONModel(:top_container).find(linked_top_container.id)
    linked_top_container.delete

    # Top Container should be dead
    expect {
      JSONModel(:top_container).find(linked_top_container.id)
    }.to raise_error(RecordNotFound)

    # Instance should be dead
    expect(
      Instance.filter(:id => instance.id).all
    ).to be_empty

    # Confirm all is still well with the resource
    resource = JSONModel(:resource).find(resource.id)
    resource.should_not eq(nil)
    resource.instances.count.should be(0)

  end

end
