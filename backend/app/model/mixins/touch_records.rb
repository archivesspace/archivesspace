module TouchRecords

  # Implement 'touch' functionality to bump related records system_mtime values
  # as 'this' record is modified in the system.

  # To implement a model should include the mixin and define the class method:
  # `touch_records`: [ { type: Resource, ids: [1, 3, 10] } ]

  # NOTE: this does not apply to _rlshp records which update related records
  # system_mtime via the trigger_reindex_of_dependants path, i.e. for
  # agents and subjects et al. using defined relationships

  def self.included(base)
    base.extend(ClassMethods)
  end

  def set_parent_and_position(*)
    super
    self.class.touch(self)
  end

  def set_root(*)
    super
    self.class.touch(self)
  end

  def delete
    self.class.touch(self)
    super
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    result = super
    self.class.touch(self)
    result
  end

  module ClassMethods

    def create_from_json(json, opts = {})
      obj = super
      touch(obj)
      obj
    end

    def touch(obj)
      return unless obj.class.respond_to? :touch_records
      records = obj.class.touch_records(obj)
      return unless records.any?
      records.each do |record_set|
        record_set[:type].update_mtime_for_ids(record_set[:ids])
      end
    end

  end

end
