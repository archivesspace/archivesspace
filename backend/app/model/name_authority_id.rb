class NameAuthorityId < Sequel::Model(:name_authority_id)
  include ASModel

  set_model_scope :global

  def validate
    validates_unique([:authority_id],
                     :message => "Authority ID must be unique")
    super
  end

end
