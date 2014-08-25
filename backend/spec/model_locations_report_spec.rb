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
    json = JSON(  String.from_java_bytes( report.render(:json) )   )
    
    json["locations"].length.should == 3 
    
    loc1 = json["locations"][0]
    loc2 = json["locations"][1]

    loc1["barcode"].should eq(location.barcode)
    loc1["building"].should eq(location.building)
    loc2["barcode"].should eq(location2.barcode)
    loc2["building"].should eq(location2.building)
    
    # unsure how to test these...let's just render them and see if there are
    # any errors. 
    report.render(:html)
    report.render(:pdf) 
    report.render(:xlsx) 
  end
end
