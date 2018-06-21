require_relative 'utils'

Sequel.migration do
  up do
    create_table(:slug) do
      primary_key :id

      Integer :sluggable_type_id
      Integer :sluggable_id
      Integer :lock_version

      String :slug
      String :created_by
      String :last_modified_by
      String :external_id

      DateTime :create_time
      DateTime :system_mtime
      DateTime :user_mtime
    end
  end

  down do
  	drop_table(:slug) 
  end
end