Feature: Assessment Create
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
  Scenario: Assessment is created
    Given the user is on the New Assessment page
     When the user clicks on the Records dropdown
      And the user clicks on 'Browse' in the dropdown menu
      And the user filters by text with the Digital Object title in the modal
      And the user selects the Digital Object from the search results in the modal
      And the user clicks on 'Link' in the modal
      And the user clicks on the Surveyed By dropdown
      And the user clicks on 'Browse' in the dropdown menu
      And the user filters by text with the Agent name in the modal
      And the user selects the Agent from the search results in the modal
      And the user clicks on 'Link' in the modal
      And the user clicks on 'Save'
     Then the 'Assessment' created message is displayed
  Scenario: Assessment is not created because required fields are missing
    Given the user is on the New Assessment page
     When the user clicks on 'Save'
     Then the following error messages are displayed
       | Records - At least 1 item(s) is required     |
       | Surveyed By - At least 1 item(s) is required |
