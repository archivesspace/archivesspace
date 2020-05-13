require 'spec_helper'
require_relative 'factories'
require_relative 'container_spec_helper'


def create_archival_object_with_rights(top_container_json, dates = [])
  rights_statements = dates.map{|date| build(:json_rights_statement, {
                                               :restriction_start_date => date[0],
                                               :restriction_end_date => date[1]
                                             })}
  archival_object = create(:json_archival_object,
                           :instances => [build_instance(top_container_json)],
                           :rights_statements => rights_statements)
  archival_object.save
end


def build_container_location(location_uri, status = 'current')
    hash = {
      'status' => status,
      'start_date' => '2000-01-01',
      'ref' => location_uri
    }
    hash['end_date'] = '2010-01-01' if status == 'previous'
    JSONModel(:container_location).from_hash(hash)
end


describe 'Managed Container model' do

  before(:each) do
    # Permissive default!
    stub_barcode_length(0, 255)
  end


  it "supports all kinds of wonderful metadata" do
    barcode = '12345678'
    ils_holding_id = '112358'
    ils_item_id = '853211'
    exported_to_ils = Time.at(1234567890).iso8601

    top_container = build(:json_top_container,
                               'barcode' => barcode,
                               'ils_holding_id' => ils_holding_id,
                               'ils_item_id' => ils_item_id,
                               'exported_to_ils' => exported_to_ils
                               )

    box_id = TopContainer.create_from_json(top_container, :repo_id => $repo_id).id

    box = TopContainer.to_jsonmodel(box_id)
    expect(box.barcode).to eq(barcode)
    expect(box.ils_holding_id).to eq(ils_holding_id)
    expect(box.ils_item_id).to eq(ils_item_id)
    expect(box.exported_to_ils).to eq(exported_to_ils)
  end


  it "can be linked to a location" do
    test_location = create(:json_location)

    container_location = JSONModel(:container_location).from_hash(
      'status' => 'current',
      'start_date' => '2000-01-01',
      'note' => 'test container location',
      'ref' => test_location.uri
    )

    container_with_location = create(:json_top_container,
                                     'container_locations' => [container_location])

    json = TopContainer.to_jsonmodel(container_with_location.id)
    expect(json['container_locations'][0]['ref']).to eq(test_location.uri)
  end


  it "doesn't blow up if you don't provide a barcode for a top-level element" do
    expect {
      create(:json_top_container, :barcode => nil)
    }.not_to raise_error
  end


  it "enforces barcode uniqueness within a repository" do
    create(:json_top_container, :barcode => "1234")

    expect {
      create(:json_top_container, :barcode => "1234")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "enforces barcode length according to config" do

    stub_barcode_length(4, 6)

    expect {
      create(:json_top_container, :barcode => "1234")
    }.not_to raise_error

    expect {
      create(:json_top_container, :barcode => "123")
    }.to raise_error(JSONModel::ValidationException)

    expect {
      create(:json_top_container, :barcode => "1234567")
    }.to raise_error(JSONModel::ValidationException)

  end


  it "can be linked to a container profile" do
    test_container_profile = create(:json_container_profile)

    container_with_profile = create(:json_top_container,
                                    'container_profile' => {'ref' => test_container_profile.uri})

    json = TopContainer.to_jsonmodel(container_with_profile.id)
    expect(json['container_profile']['ref']).to eq(test_container_profile.uri)
  end


  it "deletes all related subcontainers and instances when deleted" do
    box1 = create(:json_top_container)
    box2 = create(:json_top_container)

    acc1 = create_accession({
                              "instances" => [build_instance(box1), build_instance(box1), build_instance(box2)]
                            })

    acc2 = create_accession({
                              "instances" => [build_instance(box1), build_instance(box2), build_instance(box2)]
                            })

    TopContainer[box1.id].delete

    acc1 = Accession[acc1.id]
    acc2 = Accession[acc2.id]
    expect(acc1.instance.length).to eq(1)
    expect(acc2.instance.length).to eq(2)
  end


  describe "display strings" do

    let (:box) { create(:json_top_container, :indicator => "1", :barcode => "123") }
    let (:top_container) { TopContainer[box.id] }

    it "can show a display string for a top container that isn't linked to anything" do
      expect(top_container.display_string).to eq("#{top_container.type.capitalize} 1: [#{I18n.t("instance_container.barcode")}: 123]")
    end


    it "can find an accession linked to a given top container" do
      accession = create_accession({"instances" => [build_instance(box)]})

      collection = top_container.collections.first
      expect(collection).to be_instance_of(Accession)
      expect(collection.id).to eq(accession.id)

      expect(top_container.series).to be_empty
    end


    it "can find a resource linked to a given top container" do
      resource = create_resource({"instances" => [build_instance(box)]})

      collection = top_container.collections.first
      expect(collection).to be_instance_of(Resource)
      expect(collection.id).to eq(resource.id)

      expect(top_container.series).to be_empty
    end


    describe "archival object tree" do

      it "can find the topmost archival object linked to a given top container" do
        (resource, grandparent, parent, child) = create_tree(box)

        series = top_container.series.first
        expect(series).to be_instance_of(ArchivalObject)
        expect(series.id).to eq(grandparent.id)
      end


      it "includes the series in its JSON output" do
        (resource, grandparent, parent, child) = create_tree(box,
                                                             :grandparent_properties => {
                                                              'component_id' => 'GP1',
                                                              'level' => 'series'
                                                             })

        json = TopContainer.to_jsonmodel(top_container.id)
        expect(json.series.first).to eq({
          'ref' => grandparent.uri,
          'identifier' => grandparent.component_id,
          'display_string' => grandparent.display_string,
          'level_display_string' => "#{I18n.t("enumerations.archival_record_level.series")}",
          'publish' => false
        })
      end

      it "can get the collection linked to a given top container" do
        (resource, grandparent, parent, child) = create_tree(box)

        collection = top_container.collections.first
        expect(collection).to be_instance_of(Resource)
        expect(collection.id).to eq(resource.id)
      end

    end


    it "shows a display string for a linked series-level AO" do
      (resource, grandparent, parent, child) = create_tree(box,
                                                           :grandparent_properties => {
                                                             'level' => "series",
                                                             'component_id' => "3",
                                                           })

      expect(top_container.display_string).to eq("#{top_container.type.capitalize} 1: #{I18n.t("enumerations.archival_record_level.series")} 3 [#{I18n.t("instance_container.barcode")}: 123]")
    end

    it "doesn't show a display string for a non-series other-level AO" do
      (resource, grandparent, parent, child) = create_tree(box,
                                                           :grandparent_properties => {
                                                             'component_id' => "9",
                                                             'level' => 'otherlevel',
                                                             'other_level' => 'Handbag'
                                                           })

      expect(top_container.display_string).to eq("#{top_container.type.capitalize} 1: [#{I18n.t("instance_container.barcode")}: 123]")
    end


    it "doesn't show a display string for a topmost archival object without a component_id" do
      (resource, grandparent, parent, child) = create_tree(box,
                                                           :grandparent_properties => {
                                                             'component_id' => nil,
                                                             'level' => 'series'
                                                           })

      expect(top_container.display_string).to eq("#{top_container.type.capitalize} 1: [#{I18n.t("instance_container.barcode")}: 123]")
    end


    it "shows a display string for a valid series other-level AO" do
      (resource, grandparent, parent, child) = create_tree(box,
                                                           :grandparent_properties => {
                                                             'component_id' => "9",
                                                             'level' => 'otherlevel',
                                                             'other_level' => 'Accession'
                                                           })

      expect(top_container.display_string).to eq("#{top_container.type.capitalize} 1: Accession 9 [#{I18n.t("instance_container.barcode")}: 123]")
    end

    it "shows a display string for a linked accession" do
      accession = create_accession({"instances" => [build_instance(box)]})

      expect(top_container.display_string).to eq("#{top_container.type.capitalize} 1: [#{I18n.t("instance_container.barcode")}: 123]")
    end


    it "shows a display string for a linked resource" do
      resource = create_resource({"instances" => [build_instance(box)]})

      expect(top_container.display_string).to eq("#{top_container.type.capitalize} 1: [#{I18n.t("instance_container.barcode")}: 123]")
    end

  end


  describe "indexing" do

    let (:container_profile_json) {
      create(:json_container_profile, :name => "Cardboard box")
    }

    let (:container_profile) { ContainerProfile[container_profile_json.id] }

    let (:top_container_json) {
      create(:json_top_container,
             'container_profile' => {'ref' => container_profile_json.uri})
    }

    let (:top_container) { TopContainer[top_container_json.id] }

    it "reindexes top containers when the container profile is updated" do
      original_mtime = top_container.refresh.system_mtime
      ArchivesSpaceService.wait(:long)

      json = ContainerProfile.to_jsonmodel(container_profile)
      json.name = "Metal box"
      container_profile.update_from_json(json)

      top_container.refresh
      expect(top_container.system_mtime).to be > original_mtime
    end


    it "reindexes top containers when a linked accession is updated" do
      accession = create_accession({"instances" => [build_instance(top_container_json)]})

      original_mtime = top_container.refresh.system_mtime
      ArchivesSpaceService.wait(:long)

      json = Accession.to_jsonmodel(accession.id)
      json.title = "New accession title"

      accession.update_from_json(json)

      expect(top_container.refresh.system_mtime).to be > original_mtime
    end


    it "reindexes top containers when an archival object is updated" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      original_mtime = top_container.refresh.system_mtime
      ArchivesSpaceService.wait(:long)

      json = ArchivalObject.to_jsonmodel(grandparent.id)
      json.title = "A better title"
      ArchivalObject[grandparent.id].update_from_json(json)

      expect(top_container.refresh.system_mtime).to be > original_mtime
    end


    it "reindexes top containers when a tree is rearranged" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      original_mtime = top_container.refresh.system_mtime
      ArchivesSpaceService.wait(:long)
      ArchivalObject[child.id].set_parent_and_position(grandparent.id, 1)

      expect(top_container.refresh.system_mtime).to be > original_mtime
    end


    it "refreshes top containers when an archival object is deleted" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      original_mtime = top_container.refresh.system_mtime
      ArchivesSpaceService.wait(:long)
      ArchivalObject[child.id].delete

      expect(top_container.refresh.system_mtime).to be > original_mtime
    end


    it "refreshes top containers (linked to each tree) when two resources are merged" do
      container1_json = create(:json_top_container)
      container1 = TopContainer[container1_json.id]

      container2_json = create(:json_top_container)
      container2 = TopContainer[container2_json.id]

      (resource1, grandparent1, parent1, child1) = create_tree(container1_json)
      (resource2, grandparent2, parent2, child2) = create_tree(container2_json)

      container1_original_mtime = container1.refresh.system_mtime
      container2_original_mtime = container2.refresh.system_mtime
      ArchivesSpaceService.wait(:long)

      resource1.assimilate([resource2])

      expect(container1.refresh.system_mtime).to be > container1_original_mtime
      expect(container2.refresh.system_mtime).to be > container2_original_mtime
    end


    it "refreshes top containers when archival objects are transferred between resources (both trees)" do
      container1_json = create(:json_top_container)
      container1 = TopContainer[container1_json.id]

      container2_json = create(:json_top_container)
      container2 = TopContainer[container2_json.id]

      (resource1, grandparent1, parent1, child1) = create_tree(container1_json)
      (resource2, grandparent2, parent2, child2) = create_tree(container2_json)

      container1_original_mtime = container1.refresh.system_mtime
      container2_original_mtime = container2.refresh.system_mtime
      ArchivesSpaceService.wait(:long)

      ComponentTransfer.transfer(resource2.uri, parent1.uri)

      expect(container1.refresh.system_mtime).to be > container1_original_mtime
      expect(container2.refresh.system_mtime).to be > container2_original_mtime
    end


    it "reindexes linked archival object when top container is updated" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      ao = ArchivalObject[child.id]
      original_mtime = ao.system_mtime
      ArchivesSpaceService.wait(:long)

      json = TopContainer.to_jsonmodel(top_container_json.id)
      json.barcode = "1122334455"

      top_container.refresh.update_from_json(json)

      expect(ao.refresh.system_mtime).to be > original_mtime
    end


    it "reindexes linked archival object when top container is changed via container profile bulk update" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      ao = ArchivalObject[child.id]
      original_mtime = ao.system_mtime
      ArchivesSpaceService.wait(:long)

      json = TopContainer.to_jsonmodel(top_container_json.id)

      container_profile = create(:json_container_profile)
      TopContainer.bulk_update_container_profile([json.id],
                                                 container_profile.uri)

      expect(ao.refresh.system_mtime).to be > original_mtime
    end


    it "reindexes linked archival object when top container is changed via barcode bulk update" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      ao = ArchivalObject[child.id]
      original_mtime = ao.system_mtime
      ArchivesSpaceService.wait(:long)

      json = TopContainer.to_jsonmodel(top_container_json.id)

      barcode_data = {}
      barcode_data[json.uri] = "987654321"

      TopContainer.bulk_update_barcodes(barcode_data)

      expect(ao.refresh.system_mtime).to be > original_mtime
    end


    it "reindexes top container when it is updated with an empty location" do
      location = create(:json_location, :temporary => nil)

      container = create(:json_top_container, 'container_locations' => [build_container_location(location.uri)])

      starting_mtime = TopContainer.to_jsonmodel(container.id).system_mtime

      # Confirm that the location update doesn't occur in the same second as the initial container creation
      sleep(1) until starting_mtime != Time.now.utc.iso8601.to_s

      TopContainer.bulk_update_location([container.id], {})

      ending_mtime = TopContainer.to_jsonmodel(container.id).system_mtime

      expect(ending_mtime).to be > starting_mtime
    end

  end



  describe "bulk action" do

    describe "barcodes" do

      it "can set multiple valid barcodes" do
        container1_json = create(:json_top_container)
        container2_json = create(:json_top_container)

        barcode_data = {}
        barcode_data[container1_json.uri] = "987654321"
        barcode_data[container2_json.uri] = "876543210"

        results = TopContainer.bulk_update_barcodes(barcode_data)
        expect(results).to include(container1_json.id, container2_json.id)

        expect(TopContainer[container1_json.id].barcode).to eq("987654321")
        expect(TopContainer[container2_json.id].barcode).to eq("876543210")
      end

      it "throws exception when attempt to update to an invalid barcode" do
        container1_json = create(:json_top_container)
        container2_json = create(:json_top_container)

        stub_barcode_length(4, 6)

        barcode_data = {}
        barcode_data[container1_json.uri] = "7777777"
        barcode_data[container2_json.uri] = "333"

        expect {
          TopContainer.bulk_update_barcodes(barcode_data)
        }.to raise_error(Sequel::ValidationFailed)

      end

      it "throws exception when attempt to set duplicate barcode" do
        container1_json = create(:json_top_container)
        container2_json = create(:json_top_container)

        barcode_data = {}
        barcode_data[container1_json.uri] = "7777777"
        barcode_data[container2_json.uri] = "7777777"

        expect {
          TopContainer.bulk_update_barcodes(barcode_data)
        }.to raise_error(Sequel::ValidationFailed)

      end

      it "avoids a duplicate barcode exception when switching barcodes" do
        container1_json = create(:json_top_container, {:barcode => "11111111"})
        container2_json = create(:json_top_container, {:barcode => "22222222"})

        barcode_data = {}
        barcode_data[container1_json.uri] = "22222222"
        barcode_data[container2_json.uri] = "11111111"

        expect {
          TopContainer.bulk_update_barcodes(barcode_data)
        }.not_to raise_error

        expect(TopContainer[container1_json.id].barcode).to eq("22222222")
        expect(TopContainer[container2_json.id].barcode).to eq("11111111")
      end

    end


    describe "container profile" do

      it "can bulk update container profile" do
        container_profile1 = create(:json_container_profile)
        container_profile2 = create(:json_container_profile)

        container1 = create(:json_top_container,
                            'container_profile' => {'ref' => container_profile1.uri})
        container2 = create(:json_top_container,
                            'container_profile' => {'ref' => container_profile1.uri})
        container3 = create(:json_top_container,
                            'container_profile' => {'ref' => container_profile2.uri})
        container4 = create(:json_top_container,
                            'container_profile' => nil)

        results = TopContainer.bulk_update_container_profile([container1.id, container2.id, container3.id, container4.id],
                                                             container_profile2.uri)

        expect(results[:records_updated]).to eq(4)

        json = JSONModel(:top_container).find(container1.id)
        expect(json['container_profile']['ref']).to eq(container_profile2.uri)
      end


      it "objects if you try to bulk update to an non-existent container profile" do
        container_profile1 = create(:json_container_profile)

        container1 = create(:json_top_container,
                            'container_profile' => {'ref' => container_profile1.uri})
        container2 = create(:json_top_container,
                            'container_profile' => {'ref' => container_profile1.uri})

        results = TopContainer.bulk_update_container_profile([container1.id, container2.id],
                                                             "/container_profiles/99")

        expect(results[:error]).not_to be_nil
      end


      it "will happily remove container profiles via bulk update" do
        container_profile1 = create(:json_container_profile)

        container1 = create(:json_top_container,
                            'container_profile' => {'ref' => container_profile1.uri})
        container2 = create(:json_top_container,
                            'container_profile' => {'ref' => container_profile1.uri})

        results = TopContainer.bulk_update_container_profile([container1.id, container2.id], "")

        expect(results[:records_updated]).to eq(2)

        json = JSONModel(:top_container).find(container1.id)
        expect(json['container_profile']).to be_nil
      end

    end

    describe 'location' do

      it "can bulk update location" do
        location1 = create(:json_location, :temporary => nil)
        location2 = create(:json_location, :temporary => nil)

        container_location1 = build_container_location(location1.uri)
        container_location2 = build_container_location(location2.uri)

        container1 = create(:json_top_container, 'container_locations' => [container_location1])
        container2 = create(:json_top_container, 'container_locations' => [container_location1])
        container3 = create(:json_top_container, 'container_locations' => [container_location2])
        container4 = create(:json_top_container, 'container_locations' => nil)

        results = TopContainer.bulk_update_location([container1.id, container2.id, container3.id, container4.id],
                                                    location2.uri)

        expect(results[:records_updated]).to eq(4)

        json = JSONModel(:top_container).find(container1.id)
        expect(json['container_locations'].length).to eq(1)
        expect(json['container_locations'][0]['ref']).to eq(location2.uri)

        json = JSONModel(:top_container).find(container4.id)
        expect(json['container_locations'].length).to eq(1)
        expect(json['container_locations'][0]['ref']).to eq(location2.uri)
      end


      it "doesn't mess with previous locations" do
        location1 = create(:json_location, :temporary => nil)
        location2 = create(:json_location, :temporary => nil)
        temp_location = create(:json_location, :temporary => 'loan')

        container_location1 = build_container_location(location1.uri)
        prev_container_location = build_container_location(temp_location.uri, 'previous')

        container1 = create(:json_top_container, 'container_locations' => [container_location1, prev_container_location])

        TopContainer.bulk_update_location([container1.id], location2.uri)

        json = JSONModel(:top_container).find(container1.id)
        expect(json['container_locations'].length).to eq(2)
        expect(json['container_locations'].map{|v| v['ref']}.include?(location2.uri)).to be_truthy
        expect(json['container_locations'].map{|v| v['ref']}.include?(temp_location.uri)).to be_truthy
      end

      it "removes location if updated with a blank location" do
        location = create(:json_location, :temporary => nil)

        container = create(:json_top_container, 'container_locations' => [build_container_location(location.uri)])

        results = TopContainer.bulk_update_location([container.id], {})

        expect {
          results.to eq(1)
        }

        json = JSONModel(:top_container).find(container.id)

        expect(json['container_locations'].length).to eq(0)
        expect(json['container_locations'].empty?).to be_truthy
      end


      it "replaces all current locations with the new one" do
        location1 = create(:json_location, :temporary => nil)
        location2 = create(:json_location, :temporary => nil)
        location3 = create(:json_location, :temporary => nil)

        container_location1 = build_container_location(location1.uri)
        container_location2 = build_container_location(location2.uri)

        container1 = create(:json_top_container, 'container_locations' => [container_location1, container_location2])

        TopContainer.bulk_update_location([container1.id], location3.uri)

        json = JSONModel(:top_container).find(container1.id)
        expect(json['container_locations'].length).to eq(1)
        expect(json['container_locations'][0]['ref']).to eq(location3.uri)
      end


      it "complains if the new location doesn't exist" do
        container1 = create(:json_top_container, 'container_locations' => [])
        results = TopContainer.bulk_update_location([container1.id], '/locations/duff')
        expect(results[:error]).not_to be_nil
      end

    end

  end


    it "reindexes linked records when a top container is updated" do
      box = create(:json_top_container)

      accessions = []
      accessions << create_accession({"instances" => [build_instance(box)]})
      accessions << create_accession({"instances" => [build_instance(box)]})
      accessions << create_accession({"instances" => [build_instance(box)]})

      mtimes = accessions.map {|accession| accession.system_mtime}
      ArchivesSpaceService.wait(:long)

      # Refresh our lock version
      box = TopContainer.to_jsonmodel(box.id)

      TopContainer[box.id].update_from_json(box)

      expect(mtimes).not_to eq(accessions.map {|accession| accession.refresh.system_mtime})
    end


end
