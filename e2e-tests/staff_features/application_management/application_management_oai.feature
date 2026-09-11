Feature: OAI-PMH settings can be adjusted and OAI-PMH endpoint is available
  Background:
    Given an administrator user is logged in
  Scenario Outline: Update OAI-PMH Settings
     When the user clicks on 'System'
      And the user clicks on 'Manage OAI-PMH Settings'
      And the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Update OAI-PMH Settings'
     Then the 'OAI-PMH settings' updated message is displayed
      And the field '<Field>' has value '<NewValue>'
        Examples:
          | Field               | NewValue                    |
          | OAI Admin Email     | archivist@example.org       |
  Scenario: Verify that OAI-PMH endpoint is available
     When the user visits the OAI-PMH endpoint using the verb Identify
     Then an XML response beginning with "<OAI-PMH xmlns=" is displayed
  Scenario: Define more than one repository set and more than one sponsor set
    Given a Repository with name 'oai_set_test' has been created
     When the user clicks on 'System'
      And the user clicks on 'Manage OAI-PMH Settings'
      And the user removes every OAI set
      And the user adds an OAI repository set named 'oai_repo_set_a' for the repository 'repository_test'
      And the user adds an OAI repository set named 'oai_repo_set_b' for the repository 'oai_set_test'
      And the user adds an OAI sponsor set named 'oai_sponsor_set_a' for the sponsors 'Sponsor One'
      And the user adds an OAI sponsor set named 'oai_sponsor_set_b' for the sponsors 'Sponsor Two, Sponsor Three'
      And the user clicks on 'Update OAI-PMH Settings'
     Then the 'OAI-PMH settings' updated message is displayed
      And the OAI repository set 'oai_repo_set_a' includes the repository 'repository_test'
      And the OAI repository set 'oai_repo_set_b' includes the repository 'oai_set_test'
      And the OAI sponsor set 'oai_sponsor_set_b' includes the sponsors 'Sponsor Two, Sponsor Three'
      And the OAI-PMH endpoint offers the sets 'oai_repo_set_a, oai_repo_set_b, oai_sponsor_set_a, oai_sponsor_set_b'
  Scenario: Remove one repository set and keep the rest
     When the user clicks on 'System'
      And the user clicks on 'Manage OAI-PMH Settings'
      And the user removes every OAI set
      And the user adds an OAI repository set named 'oai_repo_set_kept' for the repository 'repository_test'
      And the user adds an OAI repository set named 'oai_repo_set_removed' for the repository 'repository_test'
      And the user clicks on 'Update OAI-PMH Settings'
      And the user removes the OAI repository set 'oai_repo_set_removed'
      And the user clicks on 'Update OAI-PMH Settings'
     Then the 'OAI-PMH settings' updated message is displayed
      And the OAI-PMH endpoint offers the sets 'oai_repo_set_kept'
      And the OAI-PMH endpoint does not offer the set 'oai_repo_set_removed'
