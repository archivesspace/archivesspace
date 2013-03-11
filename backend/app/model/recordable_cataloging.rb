module RecordableCataloging
  
  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def self.create_from_json(json, opts = {})

      obj = super

      user = User[:username => RequestContext.get(:current_username)]

      date = JSONModel(:date).from_hash(
                :label => 'creation', 
                :date_type => 'single', 
                :begin => obj.create_time.strftime("%Y-%m-%d"), 
                :begin_time => obj.create_time.strftime("%H:%M:%S"),
                )

      event = JSONModel(:event).from_hash(
                :linked_agents => [{:ref => user.uri, :role => 'implementer'}], 
                :event_type => 'cataloging', 
                :date => date, 
                :linked_records => [{:ref => obj.uri, :role => 'outcome'}]
                )


      # Use the global repository to capture events about global records
      RequestContext.open(:repo_id => 1) do

        event_obj = Event.create_from_json(event)
      end

      obj
    end
    
  end
  
end