class RevisionStatement < Sequel::Model(:revision_statement)
  include ASModel
  corresponds_to JSONModel(:revision_statement)
  set_model_scope :repository
end
