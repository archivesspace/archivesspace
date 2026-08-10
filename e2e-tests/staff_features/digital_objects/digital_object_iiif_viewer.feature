Feature: Digital Object IIIF viewer
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
      And the Digital Object is opened in edit mode
      And the user has added an IIIF manifest File Version to the Digital Object
  Scenario: The bundled viewer renders the manifest in the staff interface
     When the user is on the Digital Object view page
      And the user expands the File Version
     Then the bundled Universal Viewer is embedded
      And the viewer renders the IIIF manifest
  Scenario: The bundled viewer renders the manifest in the public interface
    Given the Digital Object is published
     When the user is on the Digital Object page in the public interface
     Then the bundled Universal Viewer is embedded
      And the viewer renders the IIIF manifest
