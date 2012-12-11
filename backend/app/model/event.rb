require_relative 'relationships'

class Event < Sequel::Model(:event)

  include ASModel
  include Relationships
  include Agents

  set_model_scope :repository
  corresponds_to JSONModel(:event)

  enable_suppression

  one_to_many :date, :class => "ASDate"
  jsonmodel_hint(:the_property => :date,
                 :contains_records_of_type => :date,
                 :corresponding_to_association => :date,
                 :is_array => false,
                 :always_resolve => true)

  define_relationship(:name => :link,
                      :json_property => 'linked_records',
                      :contains_references_to_types => proc {[Accession, Resource, ArchivalObject]})


  def self.linkable_records_for(prefix)
    linked_models(:link).map do |model|
      [model.my_jsonmodel.record_type, model.records_matching(prefix, 10)]
    end
  end


  def has_active_linked_records?
    linked_records(:link).each do |linked_record|
      if linked_record.values.has_key?(:suppressed) && linked_record[:suppressed] == 0
        return true
      end
    end

    return false
  end


  # Look for events that link to a given record.  If we find any, consider
  # suppressing them if they have no active linked records
  def self.handle_suppressed(record)
    events = instances_relating_to(record)

    events.each do |event|
      val = !event.has_active_linked_records?
      event.set_suppressed(val)
    end
  end


  def set_suppressed(suppress)
    self.suppressed = (suppress ? 1 : 0)
    save

    suppress
  end

end
