Feature: Repository Edit
  Background:
    Given an administrator user is logged in
      And a Repository has been created
  Scenario: Repository is opened in the edit mode from the browse menu
    Given the Repository appears in the search results list
     When the user clicks on 'Edit'
     Then the Repository is opened in edit mode
  Scenario: Repository is opened in the edit mode from the view mode
    Given the Repository is opened in the view mode
     When the user clicks on 'Edit'
     Then the Repository is opened in edit mode
  Scenario: Repository is not updated after changes are canceled
    Given the Repository is opened in edit mode
     When the user changes the 'Short Name' field
      And the user clicks on 'Cancel'
     Then the Repository Short Name field has the original value
  Scenario: Delete required field of a Repository fails
    Given the Repository is opened in edit mode
     When the user clears the 'Repository Short Name' field
      And the user clicks on 'Save Repository'
     Then the following error messages are displayed
       | Repository Short Name - Property is required but was missing  |
     Then the Repository Short Name field has the original value
