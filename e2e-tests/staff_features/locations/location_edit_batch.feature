Feature: Location Edit Batch
  Background:
    Given an administrator user is logged in
      And two Locations A & B have been created
      And the two Locations are displayed in the search results
  Scenario: Edit Batch
     When the user checks Location A and Location B
      And the user clicks on 'Edit Batch'
      And the user clicks on 'Edit Records' in the modal
      And the user fills in 'Building' with 'Test Batch Building'
      And the user clicks on 'Update Locations'
     Then the '2 Locations' updated message is displayed
      And the two Locations have the following values
        | form_field | form_value    |
        | Building   | Test Batch Building |
