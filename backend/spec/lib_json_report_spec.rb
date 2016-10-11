require 'spec_helper'

describe 'JSON Jasper Report model' do
  
  before(:all) do
    opts = { "report_type" => "json",
              "uri_suffix" => "locations",
              "description" => "a stupid lil test",
              "query" => "
             results = nil
             DB.open do |db|
               locations = db[:location].select(:building, :title, :floor, :room, :area, :barcode, :classification, :id ).all
               resources = db[:location].
               join(:housed_at_rlshp, :location_id => :location__id).
               join(:container, :id => :housed_at_rlshp__container_id).
               join(:instance,{ :id => :container__instance_id} , :table_alias => :instance ).
               join(:enumeration_value, :id => :instance__instance_type_id).
               join(:resource, { :id => :instance__resource_id }, :table_alias => :resource ).
               join(:repository, :id => :resource__repo_id).
               where(Sequel.qualify(:repository, :id) => @repo_id).
               select(:resource__id, :resource__title, Sequel.as( :location__id, :location_id), Sequel.as( :enumeration_value__value, :instance_type)).
               all
               accessions = db[:location].
               join(:housed_at_rlshp, :location_id => :location__id).
               join(:container, :id => :housed_at_rlshp__container_id).
               join(:instance, :id => :container__instance_id).
               join(:accession, :id => :instance__accession_id).
               join(:repository, :id => :accession__repo_id).
               where(Sequel.qualify(:repository, :id) => @repo_id).
               select(:accession__id, :accession__title, :accession__identifier, Sequel.as( :location__id, :location_id)).
               all
             results = { :locations => locations, :resources => resources, :accessions => accessions }
            end
            results
          " 
    
            }
    JasperReportRegister.register_report(opts)

    query = eval( "Proc.new{ #{opts["query"] }  }" )
    LocationsReport.send(:define_method, :query) { query.call } 
  
  end
 
  it "should have registered correctly" do
    report = LocationsReport.new({:repo_id => $repo_id},
                                  Job.create_from_json(build(:json_job),
                                                       :repo_id => $repo_id,
                                                       :user => create_nobody_user))
    report.should be_kind_of(JSONReport) 
    report.should be_kind_of(JasperReport) 
  end
  
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

    report = LocationsReport.new({:repo_id => $repo_id},
                                  Job.create_from_json(build(:json_job),
                                                       :repo_id => $repo_id,
                                                       :user => create_nobody_user))
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
    #report.render(:html)
    #report.render(:pdf) 
    #report.render(:xlsx) 
  end
end
