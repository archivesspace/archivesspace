Feature: Digital Object merge
  Background:
    Given an administrator user is logged in
      And two Digital Objects A & B have been created
  Scenario: Merge two Digital Objects by browsing
    Given the Digital Object A is opened in edit mode
     When the user clicks on 'Merge'
      And the user clicks on the dropdown in the merge dropdown form
      And the user clicks on 'Browse' in the merge dropdown form
      And the user filters by text with the Digital Object B title in the modal
      And the user selects the Digital Object B from the search results in the modal
      And the user clicks on 'Link' in the modal
      And the user clicks on 'Merge' in the merge dropdown form
      And the user clicks on 'Merge' in the modal
     Then the 'Digital Object(s)' merged message is displayed
      And the Digital Object B is deleted
      And the following linked records from the Digital Object B are appended to the Digital Object A
        | Agent Links        |
        | Subjects           |
        | Classifications    |
  Scenario: Merge two Digital Objects by searching
    Given the Digital Object A is opened in edit mode
     When the user clicks on 'Merge'
      And the user fills in and selects the Digital Object B in the merge dropdown form
      And the user clicks on 'Merge' in the merge dropdown form
      And the user clicks on 'Merge' in the modal
     Then the 'Digital Object(s)' merged message is displayed
      And the Digital Object B is deleted
      And the following linked records from the Digital Object B are appended to the Digital Object A
        | Agent Links        |
        | Subjects           |
        | Classifications    |
  Scenario: Merge two Digital Objects by creating the second Digital Object
    Given the Digital Object A is opened in edit mode
     When the user clicks on 'Merge'
      And the user clicks on the dropdown in the merge dropdown form
      And the user clicks on 'Create' in the merge dropdown form
      And the user fills in 'Title' with 'B' in the modal
      And the user fills in 'Identifier' in the modal
      And the user clicks on 'Create and Link' in the modal
      And the user clicks on 'Merge' in the dropdown menu
      And the user clicks on 'Merge' in the modal
     Then the 'Digital Object(s)' merged message is displayed
