Feature: Subject View
  Background:
    Given an administrator user is logged in
  Scenario: Search Subject by title
    Given a Subject has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Subjects'
      And the user filters by text with the Subject term
     Then the Subject is in the search results
  Scenario: View Subject from the search results
    Given a Subject has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Subjects'
      And the user filters by text with the Subject term
      And the user clicks on 'View'
     Then the Subject view page is displayed
  Scenario: Sort Subjects by term
    Given two Subjects have been created with a common keyword in their term
      And the two Subjects are displayed sorted by ascending term
     When the user clicks on 'Terms'
     Then the two Subjects are displayed sorted by descending term
  Scenario: Sort Subjects by date created
    Given two Subjects have been created with a common keyword in their term
      And the two Subjects are displayed sorted by ascending term
     When the user clicks on 'Terms Ascending'
      And the user hovers on 'Created' in the dropdown menu
      And the user clicks on 'Ascending' in the dropdown menu
     Then the two Subjects are displayed sorted by ascending created date
  Scenario: Sort Subjects by modified date
    Given two Subjects have been created with a common keyword in their term
      And the two Subjects are displayed sorted by ascending term
     When the user clicks on 'Terms Ascending'
      And the user hovers on 'Modified' in the dropdown menu
      And the user clicks on 'Ascending' in the dropdown menu
     Then the two Subjects are displayed sorted by ascending modified date
