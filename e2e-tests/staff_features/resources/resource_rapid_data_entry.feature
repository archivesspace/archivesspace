Feature: Resource Rapid Data Entry
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Add a new resource component row with valid data
     When the user clicks on 'Rapid Data Entry'
      And the user selects 'File' from 'Level of Description' in the first row of the Rapid Data Entry table
      And the user fills in 'Title' with 'Default Test Title' in the first row of the Rapid Data Entry table
      And the user selects 'Single' from 'Date Type' in the first row of the Rapid Data Entry table
      And the user fills in 'Begin' with '2021' in the first row of the Rapid Data Entry table
      And the user clicks on 'Add Row' in the modal
     Then a new row with the following data is added to the Rapid Data Entry table
       | Level of Description | File               |
       | Date Type            | Single             |
       | Begin                | 2021               |
  Scenario: Validate row succeeds
     When the user clicks on 'Rapid Data Entry'
      And the user selects 'File' from 'Level of Description' in the first row of the Rapid Data Entry table
      And the user fills in 'Title' with 'Default Test Title' in the first row of the Rapid Data Entry table
      And the user selects 'Single' from 'Date Type' in the first row of the Rapid Data Entry table
      And the user fills in 'Begin' with '2021' in the first row of the Rapid Data Entry table
      And the user clicks on 'Validate Rows' in the modal
     Then the following message is displayed
       | All rows are valid |
  Scenario: Validate row fails
     When the user clicks on 'Rapid Data Entry'
      And the user clicks on 'Validate Rows' in the modal
     Then the following error messages are displayed
       | 1 row(s) with an error - click a row field to view the errors for that row |
  Scenario: Remove a column from the Rapid Data Entry table
     When the user clicks on 'Rapid Data Entry'
      And the user clicks on 'Columns: 45 visible'
      And the user unchecks the 'Basic Information - Title' checkbox in the dropdown menu
     Then the 'Basic Information - Title' column is no longer visible in the Rapid Data Entry table
  Scenario: Fill a column with a designated value
     When the user clicks on 'Rapid Data Entry'
      And the user clicks on 'Fill Column'
      And the user selects 'Basic Information - Level of Description' from 'Column' in the modal
      And the user selects 'Class' from 'Fill Value' in the modal
      And the user clicks on 'Apply Fill' in the modal
     Then the 'Level of Description' has value 'Class' in all rows
  Scenario: Save a Rapid Data Entry Template
     When the user clicks on 'Rapid Data Entry'
      And the user selects 'File' from 'Level of Description' in the first row of the Rapid Data Entry table
      And the user fills in 'Title' with 'Default Test Title' in the first row of the Rapid Data Entry table
      And the user selects 'Single' from 'Date Type' in the first row of the Rapid Data Entry table
      And the user fills in 'Begin' with '2021' in the first row of the Rapid Data Entry table
      And the user clicks on 'Save as Template' in the modal
      And the user fills in 'Template name' with 'Test Template'
      And the user clicks on 'Save Template'
     Then a new template with name 'Test Template' with the following data is added to the Resource Rapid Data Entry templates
       | Level of Description | File               |
       | Title                | Default Test Title |
       | Date Type            | Single             |
       | Begin                | 2021               |
  Scenario: Remove a Rapid Data Entry Template
    Given a Resource Rapid Data Entry template has been created
      And the Resource is opened in edit mode
     When the user clicks on 'Rapid Data Entry'
      And the user clicks on 'Remove Templates' in the modal
      And the user checks the created Rapid Data Entry template
      And the user clicks on 'Confirm Removal'
     Then the template is removed from the Resource Rapid Data Entry templates
