Feature: Digital Object Component Create
  Background:
    Given an administrator user is logged in
  Scenario: Create a Child Digital Object
    Given a Digital Object has been created
      And the Digital Object is opened in edit mode
     When the user clicks on 'Add Child'
      And the user fills in 'Label' with 'Digital Object Component Label Child'
      And the user clicks on 'Save'
     Then the 'Digital Object Component' created message is displayed
      And the Digital Object Component with Label 'Digital Object Component Label Child' is saved as a child of the Digital Object
  Scenario: Create a Sibling Digital Object
    Given a Digital Object with a Digital Object Component has been created
      And the Digital Object is opened in edit mode
     When the user selects the Digital Object Component
      And the user clicks on 'Add Sibling'
      And the user fills in 'Label' with 'Digital Object Component Label Sibling'
      And the user clicks on 'Save'
     Then the 'Digital Object Component' created message is displayed
      And the Digital Object Component with Title 'Digital Object Component Label Sibling' is saved as a sibling of the selected Digital Object Component
