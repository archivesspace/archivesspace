Feature: Top Container Edit
  Background:
    Given an administrator user is logged in
      And a Resource with a Top Container has been created
  Scenario: Top Container is opened in the edit mode from the search results
    Given the user is on the Top Containers page
     When the user fills in 'Keyword' with the Resource title
     When the user clicks on 'Search'
      And the user clicks on 'Edit'
     Then the Top Container is opened in the edit mode
  Scenario: Top Container is opened in the edit mode from the view mode
    Given the user is on the Top Container view page
     When the user clicks on 'Edit'
     Then the Top Container is opened in the edit mode
  Scenario Outline: Top container basic information is successfully updated
    Given the Top Container is opened in edit mode
     When the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Save'
      And the user clicks on 'Edit'
     Then the field '<Field>' has value '<NewValue>'
       Examples:
         | Field          | NewValue      |
         | ILS Holding ID | 1234355643453 |
  Scenario: Top Container is not updated after changes are canceled
    Given the Top Container is opened in edit mode
     When the user changes the 'Indicator' field
      And the user clicks on 'Cancel'
     Then the Indicator field has the original value
      And the user is on the Top Containers page
  Scenario: Location is added successfully to the Top Container
    Given the Top Container is opened in edit mode
     When the user clicks on 'Add Location' in the 'Locations' form
      And the user clicks on the first dropdown in the "Locations" form
      And the user clicks on 'Browse' in the dropdown menu
      And the user selects the Test Location in the modal
      And the user clicks on 'Link' in the modal
      And the user clicks on 'Save Top Container'
     Then the 'Top Container' updated message is displayed
      And the location is added to the Top Container
  Scenario: Location is not added to the Top Container due to missing required field
    Given the Top Container is opened in edit mode
     When the user clicks on 'Add Location' in the 'Locations' form
      And the user clicks on 'Save Top Container'
     Then the following error message is displayed
       | Location - Property is required but was missing |
  Scenario: Top Container is deleted from the view page
    Given the user is on the Top Container view page
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the Top Containers page is displayed
      And the Top Container is deleted
  Scenario: Cancel Top Container delete from the view page
    Given the user is on the Top Container view page
     When the user clicks on 'Delete'
      And the user clicks on 'Cancel'
     Then the user is still on the Top Container view page
  Scenario: Top Container is deleted from the edit page
    Given the Top Container is opened in edit mode
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the Top Containers page is displayed
      And the Top Container is deleted
  Scenario: Cancel Top Container delete from the edit page
    Given the Top Container is opened in edit mode
     When the user clicks on 'Delete'
      And the user clicks on 'Cancel' in the modal
     Then the user is still on the Top Container edit page
