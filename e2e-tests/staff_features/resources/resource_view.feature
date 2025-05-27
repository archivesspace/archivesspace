Feature: Resource View
  Background:
    Given an administrator user is logged in
  Scenario: Search Resource by title
    Given a Resource has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Resources'
      And the user filters by text with the Resource title
     Then the Resource is in the search results
  Scenario: View Resource from the search results
    Given a Resource has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Resources'
      And the user filters by text with the Resource title
      And the user clicks on 'View'
     Then the Resource view page is displayed
  Scenario: Sort Resources by title
    Given two Resources have been created with a common keyword in their title
      And the two Resources are displayed sorted by ascending title
     When the user clicks on 'Title'
     Then the two Resources are displayed sorted by descending title
  Scenario: Sort Resources by identifier
    Given two Resources have been created with a common keyword in their title
      And the two Resources are displayed sorted by ascending title
     When the user clicks on 'Identifier'
     Then the two Resources are displayed sorted by ascending identifier
  Scenario: Sort Resources by level
    Given two Resources have been created with a common keyword in their title
      And the two Resources are displayed sorted by ascending title
     When the user clicks on 'Level'
     Then the two Resources are displayed sorted by ascending level
