Feature: Repository View
  Background:
    Given an administrator user is logged in
  Scenario: Search Repository by title
    Given a Repository has been created
     When the user clicks on 'System'
      And the user clicks on 'Manage Repositories'
      And the user filters by text with the Repository name
     Then the Repository is in the search results
  Scenario: View Repository from the search results
    Given a Repository has been created
     When the user clicks on 'System'
      And the user clicks on 'Manage Repositories'
      And the user filters by text with the Repository name
      And the user clicks on 'View'
     Then the Repository view page is displayed
  Scenario: Sort Repositories by title
    Given two Repositories have been created with a common keyword in their title
      And the two Repositories are displayed sorted by ascending title in the searh results
     When the user clicks on 'Title'
     Then the two Repositories are displayed sorted by ascending title
