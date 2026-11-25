require 'file_uri'

# Before the Display Thumbnail flags, a Resource or Archival Object page without a representative
# instance showed one image or generic icon per Digital Object instance whose Digital Object is
# published and has a published http, https or data: File Version. Where that was exactly one
# instance, it becomes representative, so that the record keeps showing it. Records with several are
# left to the archivist (ANW-3070).
Sequel.migration do
  up do
    [:resource, :archival_object].each do |record_type|
      fk_column = :"#{record_type}_id"

      # Any instance type: the one-representative constraint covers them all
      with_representative = self[:instance]
                              .exclude(fk_column => nil)
                              .filter(:is_representative => 1)
                              .select(fk_column)

      shown_instance_ids = {}

      self[:instance]
        .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
        .join(:digital_object, Sequel.qualify(:digital_object, :id) => Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
        .join(:file_version, Sequel.qualify(:file_version, :digital_object_id) => Sequel.qualify(:digital_object, :id))
        .exclude(Sequel.qualify(:instance, fk_column) => nil)
        .exclude(Sequel.qualify(:instance, fk_column) => with_representative)
        .filter(Sequel.qualify(:digital_object, :publish) => 1)
        .filter(Sequel.qualify(:digital_object, :suppressed) => 0)
        .filter(Sequel.qualify(:file_version, :publish) => 1)
        .select(Sequel.qualify(:instance, :id), Sequel.qualify(:instance, fk_column), Sequel.qualify(:file_version, :file_uri))
        .each do |row|
          next unless FileURI.allowed_scheme?(row[:file_uri])

          instance_ids = (shown_instance_ids[row[fk_column]] ||= [])
          instance_ids << row[:id] unless instance_ids.include?(row[:id])
        end

      # { record id => its only shown instance id }
      single = shown_instance_ids.filter_map { |record_id, instance_ids| [record_id, instance_ids.first] if instance_ids.one? }.to_h

      single.each_slice(1000).map(&:to_h).each do |slice|
        transaction do
          self[:instance].filter(:id => slice.values).update(:is_representative => 1)
          self[record_type].filter(:id => slice.keys).update(:system_mtime => Time.now)

          # Resources whose thumbnail may now come from their tree
          if record_type == :archival_object
            self[:resource]
              .filter(:id => self[:archival_object].filter(:id => slice.keys).select(:root_record_id))
              .update(:system_mtime => Time.now)
          end
        end
      end
    end
  end

  down do
  end
end
