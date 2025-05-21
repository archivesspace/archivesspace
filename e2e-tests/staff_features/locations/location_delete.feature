Feature: Location Delete
  Background:
    Given an administrator user is logged in
      And a Location has been created
  Scenario: Location is deleted from the search results
     When the user clicks on 'Browse'
      And the user clicks on 'Locations'
      And the user filters by text with the Location building
      And the user checks the checkbox of the Location
      And the user clicks on 'Delete'
      And the user clicks on 'Delete Records'
     Then the Location is deleted
  Scenario: Location is deleted from the view page
    Given the Location view page is displayed
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the user is on the Locations page
      And the 'Location' deleted message is displayed
      And the Location is deleted
  Scenario: Cancel Location delete from the view page
    Given the Location view page is displayed
     When the user clicks on 'Delete'
      And the user clicks on 'Cancel'
     Then the user is still on the Location view page
