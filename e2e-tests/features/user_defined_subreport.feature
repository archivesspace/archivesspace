Feature: User Defined Fields in Custom Reports
  As an archivist
  I want to create custom reports that include user defined fields
  So that I can analyze custom data in my accessions

  Scenario: Create and run custom report with user defined fields for an accession
    Given an administrator user is logged in
     When the user clicks on 'System' menu
      And the user clicks on 'Manage Controlled Value Lists' link
      And the user selects "User Defined Enum 1 (user_defined_enum_1)" from "List Name"
      And the user clicks on "Create Value" button
      And the user fills in "Value" with "Test Enum 1"
      And the user clicks on "Save" button
    
      And the user selects "User Defined Enum 2 (user_defined_enum_2)" from "List Name"
      And the user clicks on "Create Value" button
      And the user fills in "Value" with "Test Enum 2"
      And the user clicks on "Save" button
    
      And the user selects "User Defined Enum 3 (user_defined_enum_3)" from "List Name"
      And the user clicks on "Create Value" button
      And the user fills in "Value" with "Test Enum 3"
      And the user clicks on "Save" button
    
      And the user selects "User Defined Enum 4 (user_defined_enum_4)" from "List Name"
      And the user clicks on "Create Value" button
      And the user fills in "Value" with "Test Enum 4"
      And the user clicks on "Save" button

     When the user clicks on 'Create' menu
      And the user clicks on 'Accession' link
      And the user fills in "Title" with "Test Accession for User Defined Report"
      And the user fills in "Identifier" with "2025" in the 1st box
      And the user fills in "Identifier" with "10" in the 2nd box
      And the user fills in "Identifier" with "9" in the 3rd box
      And the user fills in "Identifier" with "1" in the 4th box
      And the user selects "Test Enum 1" from "User Defined enum_1"
      And the user selects "Test Enum 2" from "User Defined enum_2"
      And the user selects "Test Enum 3" from "User Defined enum_3"
      And the user selects "Test Enum 4" from "User Defined enum_4"
      And the user checks "User Defined boolean_1"
      And the user checks "User Defined boolean_2"
      And the user checks "User Defined boolean_3"
      And the user fills in "User Defined integer_1" with "101"
      And the user fills in "User Defined integer_2" with "202"
      And the user fills in "User Defined integer_3" with "303"
      And the user fills in "User Defined real_1" with "1.23"
      And the user fills in "User Defined real_2" with "4.56"
      And the user fills in "User Defined real_3" with "7.89"
      And the user fills in "User Defined string_1" with "Test String 1"
      And the user fills in "User Defined string_2" with "Test String 2"
      And the user fills in "User Defined string_3" with "Test String 3"
      And the user fills in "User Defined string_4" with "Test String 4"
      And the user fills in "User Defined text_1" with "Test Text Area 1"
      And the user fills in "User Defined text_2" with "Test Text Area 2"
      And the user fills in "User Defined text_3" with "Test Text Area 3"
      And the user fills in "User Defined text_4" with "Test Text Area 4"
      And the user fills in "User Defined text_5" with "Test Text Area 5"
      And the user fills in "User Defined date_1" with "2025-10-09"
      And the user fills in "User Defined date_2" with "2025-10-10"
      And the user fills in "User Defined date_3" with "2025-10-11"
      And the user clicks on "Save Accession" button
     Then the 'Accession' created message is displayed

     When the user clicks on 'Create' menu
      And the user clicks on 'Custom Report' link
      And the user fills in "Name" with "User Defined Fields in Accessions"
      And the user selects "Accessions" from "Record Type"
      And the user checks "User Defined"
      And the user clicks on "Save Template" button
     Then the 'Template' saved message is displayed

     When the user locates the "User Defined Fields in Accessions" template
      And the user clicks on "Run" button for that template
      And the user selects "JSON" from "Format"
      And the user clicks on "Start Job" button
      And the user waits for the job to complete
     Then the user should see the following user defined values:
      | field       | value           |
      | enum_1      | Test Enum 1     |
      | enum_2      | Test Enum 2     |
      | enum_3      | Test Enum 3     |
      | enum_4      | Test Enum 4     |
      | boolean_1   | true            |
      | boolean_2   | true            |
      | boolean_3   | true            |
      | integer_1   | 101             |
      | integer_2   | 202             |
      | integer_3   | 303             |
      | real_1      | 1.23            |
      | real_2      | 4.56            |
      | real_3      | 7.89            |
      | string_1    | Test String 1   |
      | string_2    | Test String 2   |
      | string_3    | Test String 3   |
      | string_4    | Test String 4   |
      | text_1      | Test Text Area 1|
      | text_2      | Test Text Area 2|
      | text_3      | Test Text Area 3|
      | text_4      | Test Text Area 4|
      | text_5      | Test Text Area 5|
      | date_1      | 2025-10-09      |
      | date_2      | 2025-10-10      |
      | date_3      | 2025-10-11      |
