Feature: MLC content display
    Background:
        Given an administrator user is logged in
        Given a Digital Object has been created
    Scenario: Current Language selector from edit mode resource toolbar
        Given the Digital Object is opened in edit mode
        When I click the "Current Language" dropdown button
        Then I should see "English" as an option in the "Current Language" dropdown
        And I should see "Spanish" as an option in the "Current Language" dropdown
        And I should see "French" as an option in the "Current Language" dropdown
        And I should see "German" as an option in the "Current Language" dropdown
    Scenario Outline: MLC default language preview appears on mlc content fields
        Given the Digital Object is opened in edit mode
        Then I should see the MLC default language preview before the "<record_type>" "<field>" label
        And I should see the default language preview summary text "SPA"
        And the default language preview should be present but hidden
        And I should see a globe icon on the "<record_type>" "<field>" label
        Examples:
            | record_type    | field |
            | digital_object | title |
    Scenario: Current Language selector from view mode resource toolbar
        Given the Digital Object is opened in the view mode
        When I click the "Current Language" dropdown button
        Then I should see "English" as an option in the "Current Language" dropdown
        And I should see "Spanish" as an option in the "Current Language" dropdown
        And I should see "French" as an option in the "Current Language" dropdown
        And I should see "German" as an option in the "Current Language" dropdown
    Scenario Outline: MLC badge does not appear in read mode
        Given the Digital Object is opened in the view mode
        Then I should not see the MLC default language preview before the "<record_type>" "<field>" label
        And I should not see a globe icon on the "<record_type>" "<field>" label
        Examples:
            | record_type    | field |
            | digital_object | title |
