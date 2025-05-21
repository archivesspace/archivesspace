Feature: Resource Delete
  Background:
    Given an administrator user is logged in
      And a Resource has been created
  Scenario: Resource is deleted from the search results
     When the user clicks on 'Browse'
      And the user clicks on 'Resources'
      And the user filters by text with the Resource title
      And the user checks the checkbox of the Resource
      And the user clicks on 'Delete'
      And the user clicks on 'Delete Records'
     Then the 'Records' deleted message is displayed
      And the Resource is deleted
  Scenario: Resource is deleted from the view page
    Given the user is on the Resource view page
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the Resources page is displayed
      And the 'Resource' deleted message is displayed
      And the Resource is deleted
  Scenario: Cancel Resource delete from the view page
    Given the user is on the Resource view page
     When the user clicks on 'Delete'
      And the user clicks on 'Cancel'
     Then the user is still on the Resource view page
