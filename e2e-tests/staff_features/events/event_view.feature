Feature: Event View
  Background:
    Given an administrator user is logged in
  Scenario: Search Event by type
    Given an Event has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Events'
      And the user filters by text with the Event record link title
     Then the Event is in the search results
  Scenario: View Event from the search results
    Given an Event has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Events'
      And the user filters by text with the Event record link title
      And the user clicks on 'View'
     Then the Event view page is displayed
  Scenario: Sort Events by type
    Given two Events have been created with a common keyword in their record link title
      And the two Events are displayed sorted by ascending type
     When the user clicks on 'Type'
     Then the two Events are displayed sorted by descending type
  Scenario: Sort Events by Outcome
    Given two Events have been created with a common keyword in their record link title
      And the two Events are displayed sorted by ascending type
     When the user clicks on 'Outcome'
     Then the two Events are displayed sorted by ascending outcome
  Scenario: Sort Events by date created
    Given two Events have been created with a common keyword in their record link title
      And the two Events are displayed sorted by ascending type
     When the user clicks on 'Type Ascending'
      And the user hovers on 'Created' in the dropdown menu
      And the user clicks on 'Ascending' in the dropdown menu
     Then the two Events are displayed sorted by ascending created date
  Scenario: Sort Events by modified date
    Given two Events have been created with a common keyword in their record link title
      And the two Events are displayed sorted by ascending type
     When the user clicks on 'Type Ascending'
      And the user hovers on 'Modified' in the dropdown menu
      And the user clicks on 'Ascending' in the dropdown menu
     Then the two Events are displayed sorted by ascending modified date
