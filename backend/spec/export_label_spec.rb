require 'nokogiri'
require 'spec_helper'
require_relative 'export_spec_helper'


describe 'Export Labels Mappings ' do

  #######################################################################
  # FIXTURES

  def load_export_fixtures
     instances = []
    #throw in a couple non-digital instances
    rand(3).times { instances << build(:json_instance) }



    resource = create(:json_resource,
                       :instances => instances,
                       :finding_aid_status => %w(completed in_progress under_revision unprocessed).sample
                       )

    @resource = JSONModel(:resource).find(resource.id)

    @archival_objects = {}

    10.times {
      parent = [true, false].sample ? @archival_objects.keys[rand(@archival_objects.keys.length)] : nil
      a = create(:json_archival_object_normal,  :resource => {:ref => @resource.uri},
                 :parent => parent ? {:ref => parent} : nil,
                 :instances => [ build(:json_instance)]
                 )

      a = JSONModel(:archival_object).find(a.id)

      @archival_objects[a.uri] = a
     }

    3.times {
      parent = [true, false].sample ? @archival_objects.keys[rand(@archival_objects.keys.length)] : nil
      a = create(:json_archival_object_normal,  :resource => {:ref => @resource.uri},
                 :parent => parent ? {:ref => parent} : nil,
                 :instances => [ build(:json_instance,
                                       :container => build(:json_container, :barcode_1 => nil) )
                                ]
    )
      a = JSONModel(:archival_object).find(a.id)
      @archival_objects[a.uri] = a
     }

    3.times {
      parent = [true, false].sample ? @archival_objects.keys[rand(@archival_objects.keys.length)] : nil
      a = create(:json_archival_object_normal,  :resource => {:ref => @resource.uri},
                 :parent => parent ? {:ref => parent} : nil,
                 :instances => [ build(:json_instance,
                                       :container => build(:json_container, :barcode_1 => nil ) )
                                ]
    )
      a = JSONModel(:archival_object).find(a.id)
      @archival_objects[a.uri] = a
     }


    @labels = get_labels(@resource)

  end


  #######################################################################


  describe "export labels" do

    before(:each) do
      load_export_fixtures
    end

    it "should have the proper values" do
      # header, parent, 16 arch objs
      @labels.split("\r").length.should eq(18)
    end
  end


end
