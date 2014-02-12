module Events

  def self.included(base)
    ArchivesSpaceService.loaded_hook do
      base.define_relationship(:name => :event_link,
                               :json_property => 'linked_events',
                               :contains_references_to_types => proc {[Event]},
                               :class_callback => proc {|clz|
                                 clz.instance_eval do
                                   
                                   # If all of the records pointing to an event
                                   # have been suppressed, suppress the event
                                   # too.
                                   def self.handle_suppressed(ids, val)
                                     # Suppress the relationships
                                     super
                                     
                                     # Count how many unsuppressed records each event has.
                                     event_unsuppressed_counts = {}
                                     
                                     self.filter(:event_id => self.filter(:id => ids).select(:event_id)).each do |row|
                                       event_unsuppressed_counts[row[:event_id]] ||= 0
                                       
                                       if row[:suppressed] == 0
                                         event_unsuppressed_counts[row[:event_id]] += 1
                                       end
                                     end
                                     
                                     # An event whose linked records are all
                                     # suppressed gets suppressed.  Any other
                                     # event is unsuppressed.
                                     events_to_suppress = []
                                     events_to_unsuppress = []
                                     
                                     event_unsuppressed_counts.each do |event_id, count|
                                       if count == 0
                                         events_to_suppress << event_id
                                       else
                                         events_to_unsuppress << event_id
                                       end
                                     end
                                     
                                     ASModel.update_suppressed_flag(Event.filter(:id => events_to_suppress), true)
                                     ASModel.update_suppressed_flag(Event.filter(:id => events_to_unsuppress), false)
                                   end
                                 end
                               })
    end
  end

end
