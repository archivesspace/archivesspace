Feature: User Defined Fields in Custom Reports
  As an archivist
  I want to create custom reports that include user defined fields
  So that I can analyze custom data in my accessions

  @e2e
  Scenario: Create and run custom report with user defined fields for an accession
    Given I am logged in as admin
    And I click the 'System' menu
    And I click the 'Manage Controlled Value Lists' link
    # Create controlled values for enum fields
    And I select "User Defined Enum 1 (user_defined_enum_1)" from "List Name"
    And I click the "Create Value" button
    And I fill in "Value" with "Test Enum 1"
    And I click the "Save" button
    
    And I select "User Defined Enum 2 (user_defined_enum_2)" from "List Name"
    And I click the "Create Value" button
    And I fill in "Value" with "Test Enum 2"
    And I click the "Save" button
    
    And I select "User Defined Enum 3 (user_defined_enum_3)" from "List Name"
    And I click the "Create Value" button
    And I fill in "Value" with "Test Enum 3"
    And I click the "Save" button
    
    And I select "User Defined Enum 4 (user_defined_enum_4)" from "List Name"
    And I click the "Create Value" button
    And I fill in "Value" with "Test Enum 4"
    And I click the "Save" button

    # Create an accession with user defined fields
    When I click the 'Create' menu
    And I click the 'Accession' link
    And I fill in "Title" with "Test Accession for User Defined Report"
    And I fill in "Identifier" with "2025" in the 1st box
    And I fill in "Identifier" with "10" in the 2nd box
    And I fill in "Identifier" with "9" in the 3rd box
    And I fill in "Identifier" with "1" in the 4th box
    And I select "Test Enum 1" from "User Defined enum_1"
    And I select "Test Enum 2" from "User Defined enum_2"
    And I select "Test Enum 3" from "User Defined enum_3"
    And I select "Test Enum 4" from "User Defined enum_4"
    And I check "User Defined boolean_1"
    And I check "User Defined boolean_2"
    And I check "User Defined boolean_3"
    And I fill in "User Defined integer_1" with "101"
    And I fill in "User Defined integer_2" with "202"
    And I fill in "User Defined integer_3" with "303"
    And I fill in "User Defined real_1" with "1.23"
    And I fill in "User Defined real_2" with "4.56"
    And I fill in "User Defined real_3" with "7.89"
    And I fill in "User Defined string_1" with "Test String 1"
    And I fill in "User Defined string_2" with "Test String 2"
    And I fill in "User Defined string_3" with "Test String 3"
    And I fill in "User Defined string_4" with "Test String 4"
    And I fill in "User Defined text_1" with "Test Text Area 1"
    And I fill in "User Defined text_2" with "Test Text Area 2"
    And I fill in "User Defined text_3" with "Test Text Area 3"
    And I fill in "User Defined text_4" with "Test Text Area 4"
    And I fill in "User Defined text_5" with "Test Text Area 5"
    And I fill in "User Defined date_1" with "2025-10-09"
    And I fill in "User Defined date_2" with "2025-10-10"
    And I fill in "User Defined date_3" with "2025-10-11"
    And I click the "Save Accession" button
    Then I should see "Accession Test Accession for User Defined Report Created"

    # Create custom report
    When I click the 'Create' menu
    And I click the 'Custom Report' link
    And I fill in "Name" with "User Defined Fields in Accessions"
    And I select "Accessions" from "Record Type"
    And I check "User Defined"
    And I click the "Save Template" button

    # Run the report
    When I locate the "User Defined Fields in Accessions" template
    And I click the "Run" button for that template
    And I select "JSON" from "Format"
    And I click the "Start Job" button
    And I wait for the job to complete
    Then I should see the following user defined values:
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
