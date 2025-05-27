Feature: Accession Transfer
  Background:
   Given an administrator user is logged in
     And a Repository with name 'Transfer Test Repository' has been created
     And an Accession has been created
     And the Accession is opened in edit mode
  Scenario: Accession is transferred to another Repository
    When the user clicks on 'Transfer' in the record toolbar
     And the user selects 'Transfer Test Repository' from 'Destination Repository'
     And the user clicks on 'Transfer' in the transfer form
     And the user clicks on 'Transfer' in the modal
    Then the following message is displayed
      | Transfer Successful. Records may take a moment to appear in the target repository while re-indexing takes place. |
