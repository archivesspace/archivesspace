Feature: MLC content display
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
  Scenario: Current Language selector from edit mode resource toolbar
    Given the Digital Object is opened in edit mode
     When the user clicks on "Current Language"
     Then the user sees the "English" option in the "Current Language" dropdown
      And the user sees the "Spanish" option in the "Current Language" dropdown
      And the user sees the "French" option in the "Current Language" dropdown
      And the user sees the "German" option in the "Current Language" dropdown
  Scenario Outline: MLC default language preview appears on mlc content fields
    Given the Digital Object is opened in edit mode
     Then the user sees the MLC default language preview before the "<record_type>" "<field>" label
      And the user sees the default language preview summary text "SPA"
      And the default language preview should be present but hidden
      And the user sees a globe icon on the "<record_type>" "<field>" label
        Examples:
          | record_type    | field |
          | digital_object | title |
  Scenario: Current Language selector from view mode resource toolbar
    Given the Digital Object is opened in the view mode
     When the user clicks on "Current Language"
     Then the user sees the "English" option in the "Current Language" dropdown
      And the user sees the "Spanish" option in the "Current Language" dropdown
      And the user sees the "French" option in the "Current Language" dropdown
      And the user sees the "German" option in the "Current Language" dropdown
  Scenario Outline: MLC badge does not appear in read mode
    Given the Digital Object is opened in the view mode
     Then the user should not see the MLC default language preview before the "<record_type>" "<field>" label
      And the user should not see a globe icon on the "<record_type>" "<field>" label
        Examples:
          | record_type    | field |
          | digital_object | title |
