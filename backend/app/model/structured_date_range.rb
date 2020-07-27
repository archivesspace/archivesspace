class StructuredDateRange < Sequel::Model(:structured_date_range)
  include ASModel

  corresponds_to JSONModel(:structured_date_range)

  include AgentNameDates

  set_model_scope :global

  def after_create
    update_associated_name_forms
  end

  def after_update
    update_associated_name_forms
  end
end
