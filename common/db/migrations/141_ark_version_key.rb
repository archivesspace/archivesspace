require_relative 'utils'
require 'digest'
require 'json'

Sequel.migration do
  up do
    alter_table(:ark_name) do
      add_column(:version_key, String, :null => true)
    end

    self.transaction do
      self[:ark_name].update(:version_key => Digest::SHA256.hexdigest([AppConfig[:ark_naan], '', ''].to_json))
    end

    alter_table(:ark_name) do
      set_column_allow_null :version_key, false
    end
  end
end
