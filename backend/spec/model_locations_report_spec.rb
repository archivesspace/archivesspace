require 'spec_helper'

describe 'LocationsReport model' do
  it "can be created from a JSON module" do
    
    # create the record with all the instance/container etc
    location = create(:json_location, :temporary => generate(:temporary_location_type))
    Resource.create_from_json( build(:json_resource, {
      :instances => [build(:json_instance, {
        :container => build(:json_container, {
          :container_locations => [{'ref' => location.uri,
                                    'status' => 'current',
                                    'start_date' => generate(:yyyy_mm_dd),
                                    'end_date' => generate(:yyyy_mm_dd)}]
        })
      })]
    }), :repo_id => $repo_id )
      
    report = LocationsReport.new({:repo_id => $repo_id})
    report.to_enum.first[:barcode].should eq(location.barcode)
    report.to_enum.first[:building].should eq(location.building)
     
  end
end
