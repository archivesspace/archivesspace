Feature: Generic icon for representative digital material on Accessions, Resources and Archival Objects (ANW-3009)
  As an archivist I want to show a generic icon indicating representative digital material
  on accessions, resources, or archival objects with a digital object instance

  Background:
    Given an administrator user is logged in
      And a Digital Object 'Report' of type 'Text' has been created with the following File Versions
        | File       | Published | Marked as    | Caption        |
        | a document | yes       | Display Link | Report caption |

  Scenario: An Accession shows the generic icon of its representative Digital Object instance, linked to the Digital Object
    Given an Accession 'Donation' has been created with the Digital Object 'Report' as its representative instance
     When the user views the 'Donation' in the staff interface
     Then the thumbnail shows the generic icon for a 'Text' Digital Object
      And the thumbnail links to the Digital Object 'Report'
      And the thumbnail has the caption 'Report caption'
     When the user views the 'Donation' in the public interface
     Then the thumbnail shows the generic icon for a 'Text' Digital Object
      And the thumbnail links to the Digital Object 'Report'
      And the thumbnail has the caption 'Report caption'

  Scenario: An Archival Object shows the generic icon of its representative Digital Object instance, linked to the Digital Object
    Given a Resource 'Collection' has been created
      And the Resource 'Collection' has an Archival Object 'Folder' with the Digital Object 'Report' as its representative instance
     When the user views the 'Folder' in the staff interface
     Then the thumbnail shows the generic icon for a 'Text' Digital Object
      And the thumbnail links to the Digital Object 'Report'
     When the user views the 'Folder' in the public interface
     Then the thumbnail shows the generic icon for a 'Text' Digital Object
      And the thumbnail links to the Digital Object 'Report'
      And the thumbnail has the caption 'Report caption'

  Scenario: A Resource shows a generic icon when none of the representative instances of its Archival Objects shows an image
    Given a Digital Object 'Letter' has been created with the following File Versions
      | File             | Published | Marked as    | Caption |
      | another document | yes       | Display Link |         |
      And a Resource 'Collection' has been created
      And the Resource 'Collection' has an Archival Object 'First Folder' with the Digital Object 'Report' as its representative instance
      And the Resource 'Collection' has an Archival Object 'Second Folder' with the Digital Object 'Letter' as its representative instance
     When the user views the 'Collection' in the staff interface
     Then the thumbnail shows the generic icon for a 'Text' Digital Object
      And the thumbnail links to the Digital Object 'Report'
     When the user views the 'Collection' in the public interface
     Then the thumbnail shows the generic icon for a 'Text' Digital Object
      And the thumbnail links to the Digital Object 'Report'
      And the thumbnail has the caption 'Report caption'

  Scenario: A representative Digital Object without a thumbnail or generic icon shows nothing
    Given a Digital Object 'Unmarked' has been created with the following File Versions
      | File       | Published | Marked as | Caption |
      | a document | yes       |           |         |
      And an Accession 'Donation' has been created with the Digital Object 'Unmarked' as its representative instance
     When the user views the 'Donation' in the staff interface
     Then no thumbnail or generic icon is shown
     When the user views the 'Donation' in the public interface
     Then no thumbnail or generic icon is shown
