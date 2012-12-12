require_relative 'auto_id_generator'

class RightsStatement < Sequel::Model(:rights_statement)
  include ASModel
  include ExternalDocuments
  include AutoIdGenerator::Mixin

  set_model_scope :repository
  corresponds_to JSONModel(:rights_statement)

  register_auto_id :identifier


  def validate
    if self[:rights_type] === "intellectual_property"
      validates_presence([:ip_status])
      validates_presence([:jurisdiction])
    elsif self[:rights_type] === "license"
      validates_presence([:license_identifier_terms])
    elsif self[:rights_type] === "statute"
      validates_presence([:statute_citation])
      validates_presence([:jurisdiction])
    end
    super
  end

end
