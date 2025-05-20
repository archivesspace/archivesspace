Feature: Resource Event Create
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Resource Event create page
     When the user clicks on 'Add Event'
      And the user clicks on 'Add Event' in the dropdown menu
     Then the New Event page is displayed with the Resource linked
