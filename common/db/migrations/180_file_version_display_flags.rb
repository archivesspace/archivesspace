require_relative 'utils'

# Replaces file_version.is_representative with two flags:
#
#   is_display_thumbnail: the file version whose image is shown as the thumbnail
#   is_display_link:      the file version linked from the thumbnail or generic icon
#
# The flags are set from what the previous display rules showed, so that existing images and
# links keep showing: see MigrationUtils::FileVersionDisplayFlags in utils.rb for the rules.
Sequel.migration do
  up do
    alter_table(:file_version) do
      add_column(:is_display_thumbnail, Integer, :null => true, :default => nil)
      add_column(:is_display_link, Integer, :null => true, :default => nil)

      add_unique_constraint([:is_display_thumbnail, :digital_object_id], :name => 'do_one_display_thumbnail')
      add_unique_constraint([:is_display_thumbnail, :digital_object_component_id], :name => 'doc_one_display_thumbnail')
      add_unique_constraint([:is_display_link, :digital_object_id], :name => 'do_one_display_link')
      add_unique_constraint([:is_display_link, :digital_object_component_id], :name => 'doc_one_display_link')
    end

    enum_ids = FileVersionDisplayFlags.enum_ids(self)

    thumbnail_ids = []
    link_ids = []

    [:digital_object_id, :digital_object_component_id].each do |parent_column|
      self[:file_version]
        .exclude(parent_column => nil)
        .order(parent_column, :id)
        .select(:id, parent_column, :file_uri, :publish, :is_representative,
                :use_statement_id, :xlink_show_attribute_id, :file_format_name_id)
        .all
        .chunk_while { |a, b| a[parent_column] == b[parent_column] }
        .each do |file_versions|
          thumbnail, link = FileVersionDisplayFlags.choose(file_versions, enum_ids)
          thumbnail_ids << thumbnail[:id] if thumbnail
          link_ids << link[:id] if link
        end
    end

    thumbnail_ids.each_slice(1000) do |ids|
      self[:file_version].filter(:id => ids).update(:is_display_thumbnail => 1)
    end

    link_ids.each_slice(1000) do |ids|
      self[:file_version].filter(:id => ids).update(:is_display_link => 1)
    end

    alter_table(:file_version) do
      drop_constraint(:digital_object_one_representative_file_version, :type => :unique)
      drop_column(:is_representative)
    end
  end

  down do
  end
end
