Feature: Manage Top Containers from a Resource or Accession Record
  As an administrator
  I want to view and update top containers associated with a record
  So that I can manage container information without losing my place in the record

  Background:
    Given an administrator user is logged in
    And a Resource with a Top Container has been created

  Scenario: An administrator can manage top containers linked to a resource
    Given the Resource is opened in edit mode
    When the user opens the top container management panel
    Then the top container appears linked in the modal

  Scenario: An administrator can view the details of a top container
    Given the Resource is opened in edit mode
    When the user opens the top container management panel
    And the user views a top container's details
    Then the top container appears linked in the modal

  Scenario: An administrator can correct top container information from within the resource record
    Given the Resource is opened in edit mode
    When the user opens the top container management panel
    And the user updates the barcode of a top container
    Then the user is still on the Resource view page
    And the updated barcode is reflected in the top container management view

  Scenario: An administrator can apply a bulk update to top containers for a resource
    Given the Resource is opened in edit mode
    When the user opens the top container management panel
    And the user applies a bulk barcode update to the selected top containers
    And the affected top containers reflect the updated barcode

  Scenario: An administrator can manage top containers linked to an accession
    Given an Accession with a Top Container has been created
    And the Accession is opened in edit mode
    When the user opens the top container management panel
    Then the top container appears linked in the modal
