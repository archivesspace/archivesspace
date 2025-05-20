Feature: Location View
  Background:
    Given an administrator user is logged in
  Scenario: Search Location by building
    Given a Location has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Locations'
      And the user filters by text with the Location building
     Then the Location is in the search results
  Scenario: View Location from the search results
    Given a Location has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Locations'
      And the user filters by text with the Location building
      And the user clicks on 'View'
     Then the Location view page is displayed
  Scenario: Sort Location by building
    Given two Locations have been created with a common keyword in their building
      And the two Locations are displayed sorted by ascending building
     When the user clicks on 'Location'
     Then the two Locations are displayed sorted by descending building
  Scenario: Sort Locations by floor
    Given two Locations have been created with a common keyword in their building
      And the two Locations are displayed sorted by ascending building
     When the user clicks on 'Floor'
     Then the two Locations are displayed sorted by ascending floor
  Scenario: Sort Locations by room
    Given two Locations have been created with a common keyword in their building
      And the two Locations are displayed sorted by ascending building
     When the user clicks on 'Room'
     Then the two Locations are displayed sorted by ascending room
  Scenario: Sort Locations by area
    Given two Locations have been created with a common keyword in their building
      And the two Locations are displayed sorted by ascending building
     When the user clicks on 'Area'
     Then the two Locations are displayed sorted by ascending area
