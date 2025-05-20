Feature: Digital Object Delete
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
  Scenario: Digital Object is deleted from the search results
     When the user clicks on 'Browse'
      And the user clicks on 'Digital Objects'
      And the user filters by text with the Digital Object title
      And the user checks the checkbox of the Digital Object
      And the user clicks on 'Delete'
      And the user clicks on 'Delete Records'
     Then the 'Records' deleted message is displayed
      And the Digital Object is deleted
  Scenario: Digital Object is deleted from the view page
    Given the user is on the Digital Object view page
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the Digital Objects page is displayed
      And the 'Digital Object' deleted message is displayed
      And the Digital Object is deleted
  Scenario: Cancel Digital Object delete from the view page
    Given the user is on the Digital Object view page
     When the user clicks on 'Delete'
      And the user clicks on 'Cancel'
     Then the user is still on the Digital Object view page
  Scenario: Digital Object is deleted from the edit page
    Given the user is on the Digital Object edit page
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the Digital Objects page is displayed
      And the 'Digital Object' deleted message is displayed
      And the Digital Object is deleted
