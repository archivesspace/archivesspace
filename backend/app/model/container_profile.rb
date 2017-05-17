class ContainerProfile < Sequel::Model(:container_profile)
  include ASModel
  corresponds_to JSONModel(:container_profile)

  set_model_scope :global

  define_relationship(:name => :top_container_profile,
                      :contains_references_to_types => proc {[TopContainer]},
                      :is_array => false)


  def validate
    super
    validates_unique(:name, :message => "container profile name not unique")
  end


  def display_string
    "#{name} [#{depth}d, #{height}h, #{width}w #{dimension_units}] extent measured by #{extent_dimension}"
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
    end

    jsons
  end

end
