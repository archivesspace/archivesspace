class NameAuthorityId < Sequel::Model(:name_authority_id)
  include ASModel

  set_model_scope :global

  def validate
    validates_unique([:authority_id],
                     :message => "Authority ID must be unique")
    map_validation_to_json_property([:authority_id], :authority_id)

    super
  end

end
