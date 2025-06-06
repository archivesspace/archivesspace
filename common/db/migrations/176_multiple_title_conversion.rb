require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts "Adding multiple title support (Multi-Lingual Description project)"

    $stderr.puts "\tcreating title type enum"
    create_enum("title_type", ["devised", "formal", "parallel", "translated", "other"])

    $stderr.puts "\tcreating title table"
    create_table(:title) do
      primary_key :id
      Integer :resource_id
      Integer :accession_id
      Integer :archival_object_id
      Integer :digital_object_id
      Integer :digital_object_component_id
      HalfLongString :title, null: false
      DynamicEnum :type_id
      DynamicEnum :language_id
      DynamicEnum :script_id
      apply_mtime_columns
    end
    alter_table(:title) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end

    records_supporting_multiple_titles = [:resource, :archival_object, :digital_object, :digital_object_component, :accession]

    records_supporting_multiple_titles.each do |record_type|
      $stderr.puts "\tcopying titles from #{record_type} records to title table"
      self[record_type].each do |row|
        self[:title].insert(
          "#{record_type}_id".to_sym => row[:id],
          :title => row[:title] || " ",   # TODO: deal with AOs and Accessions that don't have a title
          :last_modified_by => 'admin',
          :create_time => row[:create_time],
          :system_mtime => row[:system_mtime],
          :user_mtime => row[:user_mtime]
        )
      end

      $stderr.puts "\tdeleting old title fields from #{record_type} table"
      alter_table(record_type) do
        drop_column(:title)
      end
    end
  end

  # (temporary)
  down do
    $stderr.puts "Removing multiple title support (Multi-Lingual Content project)"
    $stderr.puts "\tdeleting title type enum"
    drop_enum("title_type")
    $stderr.puts "\tdeleting title table"
    drop_table(:title)
  end
end
