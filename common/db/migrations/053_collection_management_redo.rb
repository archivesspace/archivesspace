require_relative 'utils'

def create_event_from_collection_management(dataset, event_type)

  event_type_list_id = self[:enumeration].filter( :name => 'event_event_type' ).get(:id)
  cataloged = self[:enumeration_value].filter( :enumeration_id => event_type_list_id, :value => event_type ).get(:id)
  unless cataloged
    counter = self[:enumeration_value].filter( :enumeration_id => event_type_list_id ).count
    cataloged = self[:enumeration_value].insert( :enumeration_id => event_type_list_id, :value => event_type,
                                                 :readonly => 0, :position => counter + 1  )
  end

  linked_agent_event_roles_list_id = self[:enumeration].filter(:name => "linked_agent_event_roles").get(:id)
  implementer = self[:enumeration_value].filter( :enumeration_id => linked_agent_event_roles_list_id,
                                                 :value => 'implementer' ).get(:id)

  dataset.each do |row|

    repo_id = if row[:accession_id]
                self[:accession].filter(:id => row[:accession_id]).get(:repo_id)
              elsif row[:resource_id]
                self[:resource].filter(:id => row[:resource_id]).get(:repo_id)
              elsif row[:digital_object]
                self[:digital_object].filter(:id => row[:digital_object_id]).get(:repo_id)
              else
                nil
              end

    next if repo_id.nil?

    event = self[:event].insert(
                                :json_schema_version => row[:json_schema_version],
                                :repo_id => repo_id,
                                :event_type_id => cataloged,
                                :outcome_note => row[:cataloged_note],
                                :create_time => row[:create_time],
                                :system_mtime => row[:system_mtime],
                                :user_mtime => row[:user_mtime]
                                )
    linked_event_archival_record_roles_id = self[:enumeration].filter(:name => 'linked_event_archival_record_roles').get(:id)
    outcome_id = self[:enumeration_value].filter( :enumeration_id => linked_event_archival_record_roles_id, :value => "outcome" ).get(:id)

    self[:event_link_rlshp].insert(
                                   :event_id => event,
                                   :role_id => outcome_id,
                                   :accession_id => row[:accession_id],
                                   :resource_id => row[:resource_id],
                                   :digital_object_id => row[:digital_object_id],
                                   :system_mtime => row[:system_mtime],
                                   :user_mtime => row[:user_mtime],
                                   :aspace_relationship_position => 0
                                   )

    date_type_list = self[:enumeration].filter(:name => "date_type").get(:id)
    single_date_id = self[:enumeration_value].filter(:enumeration_id => date_type_list, :value => 'single').get(:id)

    date_label_list = self[:enumeration].filter(:name => "date_label").get(:id)
    date_label_id = self[:enumeration_value].filter(:enumeration_id => date_label_list, :value => 'agent_relation').get(:id)

    begin_date = row[:user_mtime].strftime('%Y-%m-%d')
    self[:date].insert(
                       :json_schema_version => row[:json_schema_version],
                       :event_id => event,
                       :date_type_id => single_date_id,
                       :label_id => date_label_id,
                       :begin => begin_date,
                       :create_time => row[:create_time],
                       :system_mtime => row[:system_mtime],
                       :user_mtime => row[:user_mtime]
                       )

    linked_agent_row = {
      :aspace_relationship_position => 0,
      :create_time => row[:create_time],
      :system_mtime => row[:system_mtime],
      :user_mtime => row[:user_mtime],
      :role_id => implementer,
      :event_id => event
    }

    user_agent_id = self[:user].filter( :username => row[:last_modified_by] ).get(:agent_record_id)
    agent_id = self[:agent_person].filter( :id => user_agent_id ).get(:id)

    if agent_id
      linked_agent_row.merge!({:agent_person_id => agent_id })
    else # the user may not longer exist, etc. just assign it to ASpace
      agent_id = self[:agent_software].filter( :system_role => 'archivesspace_agent' ).get(:id)
      linked_agent_row.merge!({:agent_software_id => agent_id})
    end

    self[:linked_agents_rlshp].insert(linked_agent_row)

  end
end

Sequel.migration do

  up do
    # turn cataloged note into an event with type = cataloged
    create_event_from_collection_management( self[:collection_management].filter( Sequel.~(:cataloged_note => nil) ), "cataloged")
    # processing started date into an event with type = "processing_started"
    create_event_from_collection_management( self[:collection_management].filter( Sequel.~(:processing_started_date => nil) ), "processing_started")


    # take all values from processing_status and turn them into events with
    # type "processing_#{processing_status enumeration value}"
    cmps = self[:enumeration].filter( :name => 'collection_management_processing_status' ).get(:id)
    self[:enumeration_value].filter( :enumeration_id => cmps ).select(:id, :value).each do |record|
      create_event_from_collection_management( self[:collection_management].filter( :processing_status_id => record[:id] ), "processing_#{record[:value]}" )
    end


    # now we drop these columns.
    alter_table(:collection_management) do
      drop_column(:cataloged_note)
      drop_column(:processing_started_date)
      # dropping this is a PIA in mysql, so lets just leave it
      # drop_column(:processing_status_id)
    end

  end

  down do
    alter_table(:collection_management) do
      add_column(:processing_started_date, Date, :null => true)
      add_column(:cataloged_note, String, :null => true)
    end
  end

end
