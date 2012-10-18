# Handling for models that use the 4-part identifiers

module Identifiers

  def id_0=(v); @id_0 = v; self.modified!; end
  def id_1=(v); @id_1 = v; self.modified!; end
  def id_2=(v); @id_2 = v; self.modified!; end
  def id_3=(v); @id_3 = v; self.modified!; end


  def after_initialize
    # Split the identifier into its components and add the individual pieces as
    # variables on this instance.
    if self[:identifier]
      identifier = self[:identifier].split("_")
      4.times do |i|
        self.instance_eval {
          @values[:"id_#{i}"] = identifier[i]
        }

        instance_variable_set("@id_#{i}", identifier[i])
      end
    end

    super
  end

  def before_validation
    # Combine the identifier into a single string and remove the instance variables we added previously.
    self.identifier = (0...4).map {|i| instance_variable_get("@id_#{i}")}.join("_")

    4.times do |i|
      self.instance_eval {
        @values.delete(:"id_#{i}")
      }
    end

    super
  end


  def validate
    validates_unique([:repo_id, :identifier], :message => "That ID is already in use")
    map_validation_to_json_property([:repo_id, :identifier], :id_0)
    super
  end

end
