class LocationProfile < Sequel::Model(:location_profile)
  include ASModel

  corresponds_to JSONModel(:location_profile)

  set_model_scope :global

  define_relationship(:name => :location_profile,
                      :contains_references_to_types => proc {[Location]},
                      :is_array => false)

  def validate
    super
    validates_unique(:name, :message => "location profile name not unique")
  end


  def display_string
    if depth && width && height
      return "#{name} [#{depth}d, #{height}h, #{width}w #{I18n.t("enumerations.dimension_units.#{dimension_units}", :default => "")}]"
    end

    name
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
    end

    jsons
  end

end
