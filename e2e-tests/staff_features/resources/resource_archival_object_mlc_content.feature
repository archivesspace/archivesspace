Feature: MLC content display

  Background:
    Given an administrator user is logged in
      And a Resource with an Archival Object has been created

  Scenario Outline: MLC badge appears on fields marked with mlc_content_badge across form contexts
    Given the Resource is opened in edit mode
      And the user selects the Archival Object
     Then the user sees the MLC default language preview before the "<record_type>" "<field>" label
      And the user sees the default language preview summary text "SPA"
      And the default language preview should be present but hidden
      And the user sees a globe icon on the "<record_type>" "<field>" label

        Examples:
          | record_type     | field |
          | archival_object | title |

  Scenario Outline: MLC badge does not appear in read mode
    Given the Resource is opened in the view mode
      And the user selects the Archival Object
     Then the user should not see the MLC default language preview before the "<record_type>" "<field>" label
      And the user should not see a globe icon on the "<record_type>" "<field>" label

        Examples:
          | record_type     | field |
          | archival_object | title |

  @mlc_enabled
  Scenario: Current language badge appears on all subrecords when mlc enabled
    Given a second language of description has been added to the Resource
      And the Resource is opened in edit mode
      And the user selects the Archival Object
     Then the user should see language badges on all subrecords

  Scenario: Current language badge does not appear when mlc disabled
    Given the Resource is opened in edit mode
      And the user selects the Archival Object
     Then the user should not see a language badge
