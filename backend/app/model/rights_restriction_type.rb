class RightsRestrictionType < Sequel::Model(:rights_restriction_type)

  include DynamicEnums

  uses_enums(
    {:property => 'restriction_type', :uses_enum => ['restriction_type']},
    {:property => 'local_access_restriction_type', :uses_enum => ['restriction_type']},
  )

end
