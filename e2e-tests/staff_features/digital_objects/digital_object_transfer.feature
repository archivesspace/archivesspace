Feature: Digital Object Transfer
  Background:
    Given an administrator user is logged in
      And a Repository with name 'Transfer Test Repository' has been created
      And a Digital Object has been created
  Scenario: Digital Object is transferred to another Repository
    Given the Digital Object is opened in edit mode
     When the user clicks on 'Transfer' in the record toolbar
      And the user selects 'Transfer Test Repository' from 'Destination Repository'
      And the user clicks on 'Transfer' in the transfer form
      And the user clicks on 'Transfer' in the modal
     Then the following message is displayed
       | Transfer Successful. Records may take a moment to appear in the target repository while re-indexing takes place. |
