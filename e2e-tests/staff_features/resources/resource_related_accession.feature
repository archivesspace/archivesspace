Feature: Resource Related Accession Create and Link

  Background:
    Given an administrator user is logged in

  Scenario: Create and link a related accession from resource form
    Given the user is on the New Resource page
    When the user fills in 'Title'
    And the user fills in 'Identifier'
    And the user selects 'Collection' from 'Level of Description'
    And the user fills in 'Language' with 'English' and selects 'English' in the 'Languages' form
    And the user selects 'Single' from 'Type' in the 'Dates' form
    And the user fills in 'Begin' with '2026-01-01' in the 'Dates' form
    And the user fills in 'Number' with '1' in the 'Extents' form
    And the user selects 'Linear Feet' from 'Type' in the 'Extents' form
    And the user fills in 'Language of Description' with 'English' and selects 'English' in the 'Finding Aid Data' form
    And the user fills in 'Script of Description' with 'Latin' and selects 'Latin' in the 'Finding Aid Data' form
    And the user clicks on 'Add Related Accession'
    And the user clicks the dropdown toggle for related accessions
    And the user clicks on 'Create' in the dropdown menu in the 'Related Accessions' form
    Then the Related Accession creation modal is displayed

    When the user fills in 'accession_id_0_' with a unique identifier in the modal
    And the user fills in 'accession_title_' with 'Test Related Accession' in the modal
    And the user fills in 'accession_accession_date_' with '2026-01-05' in the modal
    And the user clicks on 'Create and Link' in the modal
    Then the modal should close
    And the accession 'Test Related Accession' should appear in the related accessions linker

    When the user saves the resource
    Then the resource created message is displayed
    And the related accession link should be preserved

  Scenario: Validation errors prevent inline accession creation
    Given the user is on the New Resource page
    When the user fills in 'Title'
    And the user fills in 'Identifier'
    And the user selects 'Collection' from 'Level of Description'
    And the user fills in 'Language' with 'English' and selects 'English' in the 'Languages' form
    And the user selects 'Single' from 'Type' in the 'Dates' form
    And the user fills in 'Begin' with '2026-01-01' in the 'Dates' form
    And the user fills in 'Number' with '1' in the 'Extents' form
    And the user selects 'Linear Feet' from 'Type' in the 'Extents' form
    And the user fills in 'Language of Description' with 'English' and selects 'English' in the 'Finding Aid Data' form
    And the user fills in 'Script of Description' with 'Latin' and selects 'Latin' in the 'Finding Aid Data' form
    And the user clicks on 'Add Related Accession'
    And the user clicks the dropdown toggle for related accessions
    And the user clicks on 'Create' in the dropdown menu in the 'Related Accessions' form
    And the user attempts to create an accession without required fields
    Then the following error messages are displayed in the modal
      | Identifier - Property is required but was missing |
    And the modal should remain open

    When the user fills in the missing required fields
    And the user clicks on 'Create and Link' in the modal
    Then the modal should close
    And the accession 'Incomplete Accession' should appear in the related accessions linker

  Scenario: Create multiple related accessions for a single resource
    Given the user is on the New Resource page
    When the user fills in 'Title'
    And the user fills in 'Identifier'
    And the user selects 'Collection' from 'Level of Description'
    And the user fills in 'Language' with 'English' and selects 'English' in the 'Languages' form
    And the user selects 'Single' from 'Type' in the 'Dates' form
    And the user fills in 'Begin' with '2026-01-01' in the 'Dates' form
    And the user fills in 'Number' with '1' in the 'Extents' form
    And the user selects 'Linear Feet' from 'Type' in the 'Extents' form
    And the user fills in 'Language of Description' with 'English' and selects 'English' in the 'Finding Aid Data' form
    And the user fills in 'Script of Description' with 'Latin' and selects 'Latin' in the 'Finding Aid Data' form
    And the user creates and links a related accession with title "First Accession"
    And the user creates and links a related accession with title "Second Accession"
    And the user saves the resource
    Then the resource created message is displayed
    And the resource should have 2 related accessions
    And the related accessions should be named "First Accession" and "Second Accession"

  Scenario: Create and link related accession to existing resource
    Given a Resource has been created
    When the user navigates to edit the resource
    And the user creates and links a related accession with title "New Related Accession"
    And the user saves the resource
    Then the resource updated message is displayed
    And the related accession "New Related Accession" should be linked
