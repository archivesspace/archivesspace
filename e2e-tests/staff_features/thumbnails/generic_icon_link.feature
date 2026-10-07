Feature: Link for the generic icon of Digital Objects and Digital Object Components (ANW-3006)
  As an archivist I want to associate a link with the generic icon in displays
  for digital objects and digital object components in the staff and public interface

  Background:
    Given an administrator user is logged in

  # Also covers ANW-3003: a Display Thumbnail on another File Version that the browser cannot render shows a generic icon
  Scenario: The generic icon links to the File URI of the Display Link File Version
    Given a Digital Object 'Report' has been created with the following File Versions
      | File             | Published | Marked as         | Caption |
      | a document       | yes       | Display Thumbnail |         |
      | another document | yes       |                   |         |
      | a third document | yes       | Display Link      |         |
     When the user views the 'Report' in the staff interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a document'
      And the thumbnail links to 'a third document'
     When the user views the 'Report' in the public interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a document'
      And the thumbnail links to 'a third document'

  Scenario: Without a Display Link File Version the generic icon has no link
    Given a Digital Object 'Report' has been created with the following File Versions
      | File             | Published | Marked as         | Caption |
      | a document       | yes       | Display Thumbnail |         |
      | another document | yes       |                   |         |
     When the user views the 'Report' in the staff interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a document'
      And the thumbnail has no link
      And the File Version for 'another document' is not marked as the Display Link
     When the user views the 'Report' in the public interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a document'
      And the thumbnail has no link
