require 'spec_helper'

describe 'Container Location' do

  before(:each) do
    create(:repo)
  end

  def create_container_location(opts = {})
    ContainerLocation.create_from_json(build(:json_container_location, opts))
  end


  it "can be created" do
    
    opts = {:status => generate(:container_location_status), 
            :start_date => generate(:yyyy_mm_dd)
            }
            
    cl = create_container_location(opts)

    ContainerLocation[cl[:id]].status.should eq(opts[:status])
    ContainerLocation[cl[:id]].start_date.should eq(opts[:start_date])
  end

  it "can be created with a location" do
    
    location = create(:json_location)

    opts = {:status => generate(:container_location_status), 
            :start_date => generate(:yyyy_mm_dd),
            :location => location.uri
            }

    cl = create_container_location(opts)

    ContainerLocation[cl[:id]].status.should eq(opts[:status])
    ContainerLocation[cl[:id]].start_date.should eq(opts[:start_date])
  end

  it "end date is required if the location status is previous" do
    
    opts = {:end_date => nil, 
            :status => 'current'
            }
    
    expect { create_container_location(opts) }.to_not raise_error(JSONModel::ValidationException)
    
    opts[:status] = 'previous'
    
    expect { create_container_location(opts) }.to raise_error(JSONModel::ValidationException)
    
    opts[:end_date] = generate(:yyyy_mm_dd)
    
    expect { create_container_location(opts) }.to_not raise_error(JSONModel::ValidationException)

  end

end