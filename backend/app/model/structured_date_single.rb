class StructuredDateSingle < Sequel::Model(:structured_date_single)
  include ASModel

  corresponds_to JSONModel(:structured_date_single)

  include AgentNameDates

  set_model_scope :global

  def after_create
    update_associated_name_forms
  end

  def after_update
    update_associated_name_forms
  end
end
