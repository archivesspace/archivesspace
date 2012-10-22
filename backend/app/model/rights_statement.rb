class RightsStatement < Sequel::Model(:rights_statement)
  include ASModel
  include ExternalDocuments

  plugin :validation_helpers

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
