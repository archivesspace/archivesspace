Feature: Container Profiles merge
  Background:
    Given an administrator user is logged in
      And two Container Profiles A & B have been created
      And the two Container Profiles are displayed in the search results
  Scenario: Merge two Container Profiles
    Given the two Container Profiles A & B are selected
     When the user clicks on 'Merge'
      And the user selects the Container Profile B in the Merge Container Profiles modal
      And the user clicks on 'Select merge destination' in the modal
      And the user clicks on 'Merge 2 records' in the Confirm Merge Container Profiles modal
     Then the 'Container Profiles(s)' merged message is displayed
      And the Container Profile B view page is displayed
      And the Container Profile A is deleted
