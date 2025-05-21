Feature: Subject merge
  Background:
    Given an administrator user is logged in
      And two Subjects A & B have been created
  Scenario: Merge two Subjects by browsing
    Given the Subject A is opened in edit mode
     When the user clicks on 'Merge'
      And the user clicks on the dropdown in the merge dropdown form
      And the user clicks on 'Browse' in the merge dropdown form
      And the user filters by text with the Subject B title in the modal
      And the user selects the Subject B from the search results in the modal
      And the user clicks on 'Link' in the modal
      And the user clicks on 'Merge' in the merge dropdown form
      And the user clicks on 'Merge' in the modal
     Then the 'Subject(s)' merged message is displayed
      And the Subject B is deleted
  Scenario: Merge two Subjects by searching
    Given the Subject A is opened in edit mode
     When the user clicks on 'Merge'
      And the user fills in and selects the Subject B in the merge dropdown form
      And the user clicks on 'Merge' in the merge dropdown form
      And the user clicks on 'Merge' in the modal
     Then the 'Subject(s)' merged message is displayed
      And the Subject B is deleted
