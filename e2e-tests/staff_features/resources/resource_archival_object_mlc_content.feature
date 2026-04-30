Feature: MLC content display
    Background:
        Given an administrator user is logged in
        And a Resource with an Archival Object has been created
    Scenario Outline: MLC badge appears on fields marked with mlc_content_badge across form contexts
        Given the Resource is opened in edit mode
        And the user selects the Archival Object
        Then I should see the MLC default language preview before the "<record_type>" "<field>" label
        And I should see the default language preview summary text "SPA"
        And the default language preview should be present but hidden
        And I should see a globe icon on the "<record_type>" "<field>" label
        Examples:
            | record_type     | field |
            | archival_object | title |
    Scenario Outline: MLC badge does not appear in read mode
        Given the Resource is opened in the view mode
        And the user selects the Archival Object
        Then I should not see the MLC default language preview before the "<record_type>" "<field>" label
        And I should not see a globe icon on the "<record_type>" "<field>" label
        Examples:
            | record_type     | field |
            | archival_object | title |
