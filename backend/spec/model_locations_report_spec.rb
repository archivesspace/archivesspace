require 'spec_helper'

describe 'LocationsReport model' do
=begin
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
    
    location2 = create(:json_location, :temporary => generate(:temporary_location_type))
    Accession.create_from_json( build(:json_accession, {
      :instances => [build(:json_instance, {
        :container => build(:json_container, {
          :container_locations => [{'ref' => location2.uri,
                                    'status' => 'current',
                                    'start_date' => generate(:yyyy_mm_dd),
                                    'end_date' => generate(:yyyy_mm_dd)}]
        })
      })]
    }), :repo_id => $repo_id )

    # create a third useless location to make sure it doesnt show up in the
    # report
    create(:json_location, :temporary => generate(:temporary_location_type))

    report = LocationsReport.new({:repo_id => $repo_id})
    report.to_enum.to_a.length.should == 2 
    
    
    report.to_enum.first[:barcode].should eq(location.barcode)
    report.to_enum.first[:building].should eq(location.building)
    report.to_enum.to_a.last[:barcode].should eq(location2.barcode)
    report.to_enum.to_a.last[:building].should eq(location2.building)
     
=end
end
