require 'json'

Sequel.migration do
  up do
    # For the SUI search listings and PUI records to apply the new thumbnail logic,
    # we need to reindex all published records with a potential thumbnail.

    # Reindex any published archival record with a linked published digital object
    [:accession, :resource, :archival_object].each do |record_type|
      self[record_type]
        .join(:instance, Sequel.qualify(:instance, :"#{record_type}_id") => Sequel.qualify(record_type, :id))
        .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
        .join(:digital_object, Sequel.qualify(:digital_object, :id) => Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
        .filter(Sequel.qualify(record_type, :publish) => 1)
        .filter(Sequel.qualify(:digital_object, :publish) => 1)
        .update(Sequel.qualify(record_type, :system_mtime) => Time.now)
    end

    # Reindex any published digital record
    [:digital_object, :digital_object_component].each do |record_type|
      self[record_type]
        .filter(:publish => 1)
        .update(:system_mtime => Time.now)
    end
  end
end
