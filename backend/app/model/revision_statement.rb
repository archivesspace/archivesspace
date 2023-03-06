class RevisionStatement < Sequel::Model(:revision_statement)
  include ASModel
  include Publishable
  corresponds_to JSONModel(:revision_statement)
  set_model_scope :repository
end
