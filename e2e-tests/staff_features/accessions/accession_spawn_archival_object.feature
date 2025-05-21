Feature: Accession spawn Archival Object
  Background:
    Given an administrator user is logged in
      And an Accession has been created
      And a Resource has been created
      And the Accession is opened in edit mode
  Scenario:  Archival Object form is prefilled with Accession data
     When the user clicks on 'Spawn'
      And the user clicks on 'Archival Object' in the spawn dropdown menu
      And the user selects Resource in the modal
      And the user clicks on an Archival Object in the Component Position modal
      And the user clicks on 'Insert spawned component before'
      And the user clicks on 'Select Component Position'
     Then the New Archival Object page is displayed
      And the Archival Object has been spawned from Accession info message is displayed
      And the Archival Object title is filled in with the Accession Title
      And the Archival Object publish is set from the Accession publish
      And the Archival Object notes are set from the Accession Content Description and Condition Description
      And the following Archival Object forms have the same values as the Accession
        | Agent Links       |
        | Accession Links   |
        | Subjects          |
        | Languages         |
        | Dates             |
        | Extents           |
        | Rights Statements |
