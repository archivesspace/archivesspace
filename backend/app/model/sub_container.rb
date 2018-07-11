class SubContainer < Sequel::Model(:sub_container)
  include ASModel
  corresponds_to JSONModel(:sub_container)

  set_model_scope :global

  define_relationship(:name => :top_container_link,
                      :json_property => 'top_container',
                      :contains_references_to_types => proc {[TopContainer]},
                      :is_array => false)
end
