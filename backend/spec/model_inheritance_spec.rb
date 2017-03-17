require 'spec_helper'

describe 'Record inheritance' do

  let(:resource) { create(:json_resource) }

  let(:parent) {
    create(:json_archival_object,
           :level => 'otherlevel',
           :other_level => 'special',
           :resource => {:ref => resource.uri})
  }

  let(:child) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => parent.uri})
  }

  let(:grandchild) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => child.uri})
  }

  let(:config) do
    {
      :archival_object => {
        :composite_identifiers => {
          :include_level => true,
          :identifier_delimiter => '.'
        },
        :inherited_fields => [
                              {
                                :property => 'title',
                                :inherit_directly => true
                              },
                              {
                                :property => 'component_id',
                                :inherit_directly => false
                              },
                              {
                                :property => 'linked_agents',
                                :inherit_if => proc {|json| json.select {|j| j['role'] == 'subject'} },
                                :inherit_directly => true
                              },
                              {
                                :property => 'notes',
                                :inherit_if => proc {|json| json.select {|j| j['type'] == 'scopecontent'} },
                                :inherit_directly => false
                              },
                              {
                                :property => 'notes',
                                :skip_if => proc {|json| ['file', 'item'].include?(json['level']) },
                                :inherit_if => proc {|json| json.select {|j| j['type'] == 'skippable'} },
                                :inherit_directly => false
                              }
                             ]
      }
    }
  end

  let(:json) do
    {
      'jsonmodel_type' => 'archival_object',
      'title' => 'mine all mine',
      'component_id' => nil,
      'level' => 'file',
      'linked_agents' => [],
      'notes' => [],
      'ancestors' => [
                      {
                        'ref' => '/repositories/2/archival_objects/1',
                        'level' => 'series',
                        '_resolved' => {
                          'title' => 'important series title',
                          'level' => 'series',
                          'component_id' => 'ABC',
                          'linked_agents' => [
                                              { 'role' => 'subject', 'name' => 'fred' },
                                              { 'role' => 'enemy', 'name' => 'jo' }
                                             ],
                          'notes' => [],
                        }
                      },
                      {
                        'ref' => '/repositories/2/resources/1',
                        'level' => 'collection',
                        '_resolved' => {
                          'title' => 'This is a resource',
                          'id_0' => 'RES',
                          'id_1' => '1',
                          'level' => 'collection',
                          'linked_agents' => [],
                          'notes' => [
                                        {'type' => 'scopecontent', 'text' => 'Pants'},
                                        {'type' => 'odd', 'text' => 'Something else'},
                                        {'type' => 'skippable', 'text' => 'Should be skipped'}
                                     ]
                        }
                      }
                     ]
    }
  end

  let(:record_inheritance) { RecordInheritance.new(config) }


  it "provides refs to a record's ancestors" do
    json = ArchivalObject.to_jsonmodel(grandchild.id)

    json['ancestors'].should eq([
                                  {
                                    'ref' => child.uri,
                                    'level' => child.level,
                                  },
                                  {
                                    'ref' => parent.uri,
                                    'level' => parent.other_level,
                                  },
                                  {
                                    'ref' => resource.uri,
                                    'level' => resource.level,
                                  },
                                ])
  end


  it "configurably merges field values from ancestors into a record" do
    merged = record_inheritance.merge([json]).first

    merged['title'].should eq('mine all mine')
    merged['component_id'].should eq('ABC')
  end


  it "merges only directly inherited fields if asked" do
    merged = record_inheritance.merge(json, :direct_only => true)

    merged['title'].should eq('mine all mine')
    merged['component_id'].should be_nil
  end


  it "supports selective inheritance from array values" do
    merged = record_inheritance.merge([json]).first
    
    merged['linked_agents'].select {|a| a['role'] == 'subject'}.should_not be_empty
    merged['linked_agents'].select {|a| a['role'] == 'enemy'}.should be_empty
  end


  it "supports skipping fields" do
    merged = record_inheritance.merge(json)
    
    merged['notes'].select {|a| a['type'] == 'skippable'}.should be_empty
  end


  it "adds inheritance properties to inherited values" do
    merged = record_inheritance.merge([json]).first

    scope = merged['notes'].select {|a| a['type'] == 'scopecontent'}.first
    scope['_inherited'].should_not be_nil
    scope['_inherited']['ref'].should eq('/repositories/2/resources/1')
    scope['_inherited']['level'].should eq('Collection')
    scope['_inherited']['direct'].should be false

    subject = merged['linked_agents'].select {|a| a['role'] == 'subject'}.first
    subject['_inherited']['ref'].should eq('/repositories/2/archival_objects/1')
    subject['_inherited']['level'].should eq('Series')
    subject['_inherited']['direct'].should be true

    merged['component_id_inherited']['ref'].should eq('/repositories/2/archival_objects/1')
    merged['component_id_inherited']['level'].should eq('Series')
    merged['component_id_inherited']['direct'].should be false

    merged.has_key?('title_inherited').should be false
  end


  it "adds a composite identifier" do
    merged = record_inheritance.merge(json)

    merged['_composite_identifier'].should eq('RES.1. Series ABC')
  end
end
