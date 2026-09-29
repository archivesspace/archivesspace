Feature: Generic icon for Digital Objects and Digital Object Components (ANW-3003)
  As an archivist I want to designate a generic icon to show on designated displays
  for digital objects and digital object components in the staff and public interface

  Background:
    Given an administrator user is logged in
  Scenario: A Display Link File Version without a Display Thumbnail shows a generic icon with its link
    Given a Digital Object 'Report' has been created with the following File Versions
      | File       | Published | Marked as    | Caption |
      | a document | yes       | Display Link |         |
     When the user views the 'Report' in the staff interface
     Then the thumbnail shows the generic icon
      And the thumbnail links to 'a document'
     When the user views the 'Report' in the public interface
     Then the thumbnail shows the generic icon
      And the thumbnail links to 'a document'
  Scenario: A Digital Object Component with a Display Link File Version shows a generic icon with its link
    Given a Digital Object 'Album' has been created without File Versions
      And the Digital Object 'Album' has a Digital Object Component 'Page' with the following File Versions
        | File       | Published | Marked as    | Caption |
        | a document | yes       | Display Link |         |
     When the user views the 'Page' in the staff interface
     Then the thumbnail shows the generic icon
      And the thumbnail links to 'a document'
     When the user views the 'Page' in the public interface
     Then the thumbnail shows the generic icon
      And the thumbnail links to 'a document'
  Scenario: No File Version marked Display Link or Display Thumbnail shows no thumbnail or generic icon
    Given a Digital Object 'Report' has been created with the following File Versions
      | File             | Published | Marked as | Caption |
      | an image         | yes       |           |         |
      | a document       | yes       |           |         |
     When the user views the 'Report' in the staff interface
     Then no thumbnail or generic icon is shown
     When the user views the 'Report' in the public interface
     Then no thumbnail or generic icon is shown
