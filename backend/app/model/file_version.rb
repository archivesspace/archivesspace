class FileVersion < Sequel::Model(:file_version)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:file_version)
end
