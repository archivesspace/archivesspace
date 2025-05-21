Feature: Location Create
  Background:
    Given an administrator user is logged in
  Scenario: Single Location is created
    Given the New Location page is displayed
     When the user fills in 'Building'
      And the user fills in 'Barcode'
      And the user clicks on 'Save Location'
     Then the 'Location' created message is displayed
  Scenario: Single Location is not created because required field Building is missing
    Given the New Location page is displayed
     When the user clicks on 'Save Location'
     Then the following error message is displayed
       | Building - Property is required but was missing |
  Scenario: Single Location is not created because required field Barcode is missing
    Given the New Location page is displayed
     When the user fills in 'Building'
      And the user clicks on 'Save Location'
     Then the following error message is displayed
       | You must either specify a barcode, a classification, or both a coordinate 1 label and coordinate 1 indicator |
  Scenario: Batch Location is created
    Given the New Batch Location page is displayed
     When the user fills in 'Building'
      And the user fills in Coordinate Range 1 Label with 'Test'
      And the user fills in Coordinate Range 1 Range Start with '1'
      And the user fills in Coordinate Range 1 Range End with '3'
      And the user clicks on 'Create Location'
     Then the '3 Locations' created message is displayed
  Scenario: Batch Location is not created because required fields are missing
    Given the New Batch Location page is displayed
     When the user clicks on 'Create Locations'
     Then the following error messages are displayed
       | Building - Property is required but was missing           |
       | Coordinate Range 1 - Property is required but was missing |
    Scenario: Number of Locations is previewed
      Given the New Batch Location page is displayed
       When the user fills in 'Building'
        And the user fills in Coordinate Range 1 Label with 'Test'
        And the user fills in Coordinate Range 1 Range Start with '1'
        And the user fills in Coordinate Range 1 Range End with '3'
        And the user clicks on 'Preview Locations'
       Then the Preview Locations modal with the number of Locations is displayed
