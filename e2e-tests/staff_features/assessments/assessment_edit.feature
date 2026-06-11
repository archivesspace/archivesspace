Feature: Assessment Edit
  Background:
    Given an administrator user is logged in
  Scenario: Edit Assessment
    Given an Assessment has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Assessments'
      And the user filters by text with the Assessment record
      And the user clicks on 'Edit'
      And the user clicks on the Surveyed By dropdown
      And the user clicks on 'Browse' in the dropdown menu
      And the user filters by the text 'Administrator'
      And the user selects the Agent from the search results in the modal
      And the user clicks on 'Link' in the modal
      And the user clicks on the Surveyed By dropdown
      And the user checks 'Catalog Record (MARC)'
      And the user fills in 'Extent Surveyed' with '5 linear feet'
      And the user clicks on 'Save'
     Then the 'Assessment' updated message is displayed
