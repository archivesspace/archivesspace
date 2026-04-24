Feature: Manage Top Containers from a Resource or Accession Record
  As an archivist
  I want to view and update top containers associated with a record
  So that I can manage container information without losing my place in the record

  Background:
    Given an administrator user is logged in
    And a Resource with a Top Container has been created

  Scenario: An archivist can manage top containers linked to a resource
    Given the Resource is being edited
    When the user opens the top container management panel
    Then all top containers linked to that resource are displayed

  Scenario: An archivist can view the details of a top container
    Given the Resource is being edited
    When the user opens the top container management panel
    And the archivist views a top container's details
    Then the top container information is displayed in full

  Scenario: An archivist can correct top container information from within the resource record
    Given the Resource is being edited
    When the user opens the top container management panel
    And the archivist updates the barcode of a top container
    Then the archivist remains within the resource context
    And the updated barcode is reflected in the top container management view

  Scenario: An archivist can apply a bulk update to top containers for a resource
    Given the Resource is being edited
    When the user opens the top container management panel
    And the archivist applies a bulk barcode update to the selected top containers
    Then the bulk barcode update is confirmed
    And the affected top containers reflect the updated barcode

  Scenario: An archivist can manage top containers linked to an accession
    Given an Accession with a Top Container has been created
    And the Accession is opened in edit mode
    When the user opens the top container management panel
    Then all top containers linked to that accession are displayed
