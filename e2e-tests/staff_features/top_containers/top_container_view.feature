Feature: Top Container View
  Background:
    Given an administrator user is logged in
    And a Resource with a Top Container has been created
  Scenario: View Top Container from the search results
    Given the user is on the Top Containers page
     When the user fills in 'Keyword' with the Resource title
      And the user clicks on 'Search'
      And the user clicks on 'View'
     Then the Top Container view page is displayed
