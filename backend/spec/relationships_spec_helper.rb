# frozen_string_literal: true

class RelationshipsSpecHelper
  def self.setup_database
    DB.open do |db|
      ## Database setup some additional tables for relationships
      [:apple, :banana, :cherry].each do |table|
        db.create_table! table do
          primary_key :id
          String :name
          Integer :lock_version, default: 0

          Integer :suppressed, default: 0

          String :created_by
          String :last_modified_by
          DateTime :create_time
          DateTime :system_mtime
          DateTime :user_mtime
        end
      end

      db.create_table! :fruit_salad_rlshp do
        primary_key :id
        String :sauce
        Integer :banana_id
        Integer :apple_id
        Integer :suppressed, null: false, default: 0
        Integer :aspace_relationship_position
        DateTime :system_mtime, null: false
        DateTime :user_mtime, null: false
        String :created_by
        String :last_modified_by
      end

      db.create_table! :friends_rlshp do
        primary_key :id
        Integer :banana_id_0
        Integer :apple_id_0
        Integer :banana_id_1
        Integer :apple_id_1
        Integer :cherry_id
        Integer :suppressed, null: false, default: 0

        Integer :aspace_relationship_position
        DateTime :system_mtime, null: false
        DateTime :user_mtime, null: false
        String :created_by
        String :last_modified_by
      end
    end
  end
end

RelationshipsSpecHelper.setup_database
