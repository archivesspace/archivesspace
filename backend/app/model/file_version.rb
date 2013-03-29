class FileVersion < Sequel::Model(:file_version)
  include ASModel
  corresponds_to JSONModel(:file_version)


  set_model_scope :global
end
