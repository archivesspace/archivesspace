Feature: MLC content display

  Background:
    Given an administrator user is logged in
      And a Digital Object with a Digital Object Component has been created

  Scenario Outline: MLC badge appears on fields marked with mlc_content_badge across form contexts
    Given the Digital Object is opened in edit mode
     When the user selects the Digital Object Component
     Then the user sees the MLC default language preview before the "<record_type>" "<field>" label
      And the user sees the default language preview summary text "SPA"
      And the default language preview should be present but hidden
      And the user sees a globe icon on the "<record_type>" "<field>" label

        Examples:
          | record_type              | field |
          | digital_object_component | title |
          | digital_object_component | label |

  Scenario Outline: MLC badge does not appear in read mode
    Given the Digital Object is opened in the view mode
     When the user selects the Digital Object Component
     Then the user should not see the MLC default language preview before the "<record_type>" "<field>" label
      And the user should not see a globe icon on the "<record_type>" "<field>" label

        Examples:
          | record_type              | field |
          | digital_object_component | title |
          | digital_object_component | label |

  @mlc_enabled
  Scenario: Current language badge appears on all subrecords when mlc enabled
    Given the Digital Object is opened in edit mode
     When the user selects the Digital Object Component
     Then the user should see language badges on all subrecords

  Scenario: Current language badge does not appear when mlc disabled
    Given the Digital Object is opened in edit mode
     When the user selects the Digital Object Component
     Then the user should not see a language badge
