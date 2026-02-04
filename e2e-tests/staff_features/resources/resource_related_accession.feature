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
    And the user clicks on the first dropdown in the 'Related Accessions' form
    And the user clicks on 'Create' in the dropdown menu in the 'Related Accessions' form
    And the user fills in 'Identifier' in the modal
    And the user fills in 'Title' with 'Test Related Accession' in the modal
    And the user fills in 'Accession Date' with '2026-01-05' in the modal
    And the user clicks on 'Create and Link' in the modal
    Then the accession 'Test Related Accession' appears in the related accessions linker
    When the user clicks on 'Save Resource'
    Then the 'Resource' created message is displayed
    And the accession 'Test Related Accession' is linked to the resource

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
    And the user clicks on the first dropdown in the 'Related Accessions' form
    And the user clicks on 'Create' in the dropdown menu in the 'Related Accessions' form
    And the user fills in 'Title' with 'Incomplete Accession'
    And the user clicks on 'Create and Link'
    Then the following error messages are displayed
      | Identifier - Property is required but was missing |
    And the user fills in 'Identifier' in the modal
    And the user fills in 'Date' with '2026-01-05' in the modal
    And the user clicks on 'Create and Link' in the modal
    Then the accession 'Incomplete Accession' appears in the related accessions linker

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
    And the user clicks on 'Add Related Accession'
    And the user clicks on the first dropdown in the 'Related Accessions' form
    And the user clicks on 'Create' in the dropdown menu in the 'Related Accessions' form
    And the user fills in 'Identifier' in the modal
    And the user fills in 'Title' with 'First Accession' in the modal
    And the user fills in 'Accession Date' with '2026-01-05' in the modal
    And the user clicks on 'Create and Link' in the modal
    And the user clicks on 'Add Related Accession'
    And the user clicks on the last dropdown in the 'Related Accessions' form
    And the user clicks on 'Create' in the dropdown menu in the 'Related Accessions' form
    And the user fills in 'Identifier' in the modal
    And the user fills in 'Title' with 'Second Accession' in the modal
    And the user fills in 'Accession Date' with '2026-01-05' in the modal
    And the user clicks on 'Create and Link' in the modal
    And the user clicks on 'Save Resource'
    Then the 'Resource' created message is displayed
    And the accession 'First Accession' is linked to the resource
    And the accession 'Second Accession' is linked to the resource

  Scenario: Create and link related accession to existing resource
    Given a Resource has been created
    And the Resource is opened in edit mode
    And the user clicks on 'Add Related Accession'
    And the user clicks on the first dropdown in the 'Related Accessions' form
    And the user clicks on 'Create' in the dropdown menu in the 'Related Accessions' form
    And the user fills in 'Identifier' in the modal
    And the user fills in 'Title' with 'New Related Accession' in the modal
    And the user fills in 'Accession Date' with '2026-01-05' in the modal
    And the user clicks on 'Create and Link' in the modal
    And the user clicks on 'Save Resource'
    Then the 'Resource' updated message is displayed
    And the accession 'New Related Accession' is linked to the resource
