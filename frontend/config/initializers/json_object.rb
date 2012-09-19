require "jsonmodel"

module RailsFormMixin

  def self.included(base)
    # For any array types in this schema, define a setter that will trigger
    # form_helper to do what we want.
    base.schema['properties'].each do |name, property|
      if property['type'].downcase == 'array'
        base.instance_eval do
          define_method "#{name}_attributes=" do
          end
        end
      end
    end
  end


  def persisted?
    false
  end
end


JSONModel::init(:client_mode => true,
                :mixins => [RailsFormMixin],
                :url => ArchivesSpace::Application.config.backend_url)

JSONModel::add_error_handler do |error|
  if error["code"] == "SESSION_GONE"
    raise ArchivesSpace::SessionGone.new("Your backend session was not found")
  end
end

include JSONModel

