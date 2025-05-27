Feature: Assessment View
  Background:
    Given an administrator user is logged in
  Scenario: Search Assessment by Record
    Given an Assessment has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Assessments'
      And the user filters by text with the Assessment record
     Then the Assessment is in the search results
  Scenario: View Assessment from the search results
    Given an Assessment has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Assessments'
      And the user filters by text with the Assessment record
      And the user clicks on 'View'
     Then the Assessment view page is displayed
  Scenario: Sort Assessments by ID
    Given two Assessments have been created with a common keyword in their record
      And the two Assessments are displayed sorted by ascending record in the search results
     When the user clicks on 'Assessment ID'
     Then the two Assessments are displayed sorted by ascending ID
