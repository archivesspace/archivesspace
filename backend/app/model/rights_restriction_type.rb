class RightsRestrictionType < Sequel::Model(:rights_restriction_type)

  include DynamicEnums

  uses_enums(:property => 'restriction_type', :uses_enum => ['restriction_type'])

end
