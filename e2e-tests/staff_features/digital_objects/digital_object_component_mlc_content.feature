Feature: MLC content display
    Background:
        Given an administrator user is logged in
        Given a Digital Object with a Digital Object Component has been created
    Scenario Outline: MLC badge appears on fields marked with mlc_content_badge across form contexts
        Given the Digital Object is opened in edit mode
        When the user selects the Digital Object Component
        Then I should see the MLC default language preview before the "<record_type>" "<field>" label
        And I should see the default language preview summary text "SPA"
        And the default language preview should be present but hidden
        And I should see a globe icon on the "<record_type>" "<field>" label
        Examples:
            | record_type              | field |
            | digital_object_component | title |
            | digital_object_component | label |
    Scenario Outline: MLC badge does not appear in read mode
        Given the Digital Object is opened in the view mode
        When the user selects the Digital Object Component
        Then I should not see the MLC default language preview before the "<record_type>" "<field>" label
        And I should not see a globe icon on the "<record_type>" "<field>" label
        Examples:
            | record_type              | field |
            | digital_object_component | title |
            | digital_object_component | label |
