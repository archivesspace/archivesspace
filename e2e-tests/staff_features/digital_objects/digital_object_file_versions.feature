Feature: Digital Object File versions
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
      And the Digital Object is opened in the edit mode
  Scenario: Add a single File Version with required fields
     When the user clicks on 'Add File Version' in the 'File Versions' form
      And the user fills in 'File URI' with 'http://example.com/file.pdf'
      And the user clicks on 'Save Digital Object'
     Then the 'Digital Object' updated message is displayed
      And a new File Version is added to the Digital Object with the following values
        | File URI | http://example.com/file.pdf |
  Scenario: Remove a File Version from a Digital Object
    Given the user has added a File Version to the Digital Object with the following values
      | File URI | http://example.com/file.pdf |
     When the user clicks on remove icon in the 'File Version' form
      And the user clicks on 'Confirm Removal'
      And the user clicks on 'Save Digital Object'
      And the 'Digital Object' updated message is displayed
     Then the File Version is removed from the Digital Object
