Feature: Representative image on Accessions, Resources and Archival Objects (ANW-3008, ANW-3057)
  As an archivist I want to show a representative image on accessions, resources,
  or archival objects with a digital object instance

  Background:
    Given an administrator user is logged in
      And a Digital Object 'Photograph' has been created with the following File Versions
        | File            | Published | Marked as         | Caption          |
        | a IIIF manifest | yes       |                   |                  |
        | an image        | yes       | Display Thumbnail | Photograph image |
        | a document      | yes       | Display Link      |                  |

  Scenario: An Accession shows the image of its representative Digital Object instance, linked to the Digital Object
    Given an Accession 'Donation' has been created with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Donation' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
     When the user views the 'Donation' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
      And no IIIF viewer is embedded

  Scenario: An Archival Object shows the image of its representative Digital Object instance, linked to the Digital Object
    Given a Resource 'Collection' has been created
      And the Resource 'Collection' has an Archival Object 'Folder' with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Folder' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
     When the user views the 'Folder' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
      And the bundled Universal Viewer is embedded

  Scenario: A Resource shows the image of its representative Digital Object instance and lists its Digital Objects
    Given a Resource 'Collection' has been created with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Collection' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
     When the user views the 'Collection' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
      And the public interface offers to browse 1 digital object in the collection
      And the bundled Universal Viewer is embedded

  Scenario: A Resource whose representative instance shows no image shows the image of the next representative instance of its Archival Objects
    Given a Digital Object 'Report' has been created with the following File Versions
      | File       | Published | Marked as    | Caption |
      | a document | yes       | Display Link |         |
      And a Resource 'Collection' has been created with the Digital Object 'Report' as its representative instance
      And the Resource 'Collection' has an Archival Object 'Folder' with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Collection' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
     When the user views the 'Collection' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
      And the public interface offers to browse 2 digital objects in the collection

  Scenario: An Accession shows the image of the first Digital Object Component with a display thumbnail
    Given a Digital Object 'Album' has been created with the following File Versions
      | File       | Published | Marked as | Caption |
      | a document | yes       |           |         |
      And the Digital Object 'Album' has a Digital Object Component 'Cover' with the following File Versions
        | File             | Published | Marked as | Caption |
        | another document | yes       |           |         |
      And the Digital Object 'Album' has a Digital Object Component 'Page' with the following File Versions
        | File     | Published | Marked as         | Caption    |
        | an image | yes       | Display Thumbnail | Page image |
      And an Accession 'Donation' has been created with the Digital Object 'Album' as its representative instance
     When the user views the 'Donation' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object Component 'Page'
      And the thumbnail has the caption 'Page image'
     When the user views the 'Donation' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object Component 'Page'
      And the thumbnail has the caption 'Page image'

  Scenario: An Archival Object shows the image of a Digital Object Component captioned with the component title
    Given a Digital Object 'Album' has been created without File Versions
      And the Digital Object 'Album' has a Digital Object Component 'Page' with the following File Versions
        | File     | Published | Marked as         | Caption |
        | an image | yes       | Display Thumbnail |         |
      And a Resource 'Collection' has been created
      And the Resource 'Collection' has an Archival Object 'Folder' with the Digital Object 'Album' as its representative instance
     When the user views the 'Folder' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object Component 'Page'
      And the thumbnail caption is the title of 'Page'
     When the user views the 'Folder' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object Component 'Page'
      And the thumbnail caption is the title of 'Page'

  Scenario: A Resource shows the image of a Digital Object Component and lists its Digital Objects
    Given a Digital Object 'Album' has been created without File Versions
      And the Digital Object 'Album' has a Digital Object Component 'Page' with the following File Versions
        | File     | Published | Marked as         | Caption    |
        | an image | yes       | Display Thumbnail | Page image |
      And a Resource 'Collection' has been created with the Digital Object 'Album' as its representative instance
     When the user views the 'Collection' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object Component 'Page'
      And the thumbnail has the caption 'Page image'
     When the user views the 'Collection' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object Component 'Page'
      And the thumbnail has the caption 'Page image'
      And the public interface offers to browse 1 digital object in the collection

  Scenario: A Resource shows the Digital Object Component image of its first Archival Object over the image of a later one
    Given a Digital Object 'Album' has been created without File Versions
      And the Digital Object 'Album' has a Digital Object Component 'Page' with the following File Versions
        | File     | Published | Marked as         | Caption    |
        | an image | yes       | Display Thumbnail | Page image |
      And a Resource 'Collection' has been created
      And the Resource 'Collection' has an Archival Object 'First Folder' with the Digital Object 'Album' as its representative instance
      And the Resource 'Collection' has an Archival Object 'Second Folder' with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Collection' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object Component 'Page'
     When the user views the 'Collection' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object Component 'Page'
      And the thumbnail has the caption 'Page image'

  # ANW-3009 tester case: no fallback to the image of a later Archival Object
  Scenario: A Resource shows the generic icon of the first Archival Object image the browser cannot render, linked to its Digital Object
    Given a Digital Object 'Report' has been created with the following File Versions
      | File       | Published | Marked as         | Caption |
      | a document | yes       | Display Thumbnail |         |
      And a Resource 'Collection' has been created
      And the Resource 'Collection' has an Archival Object 'First Folder' with the Digital Object 'Report' as its representative instance
      And the Resource 'Collection' has an Archival Object 'Second Folder' with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Collection' in the staff interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a document'
      And the thumbnail links to the Digital Object 'Report'
     When the user views the 'Collection' in the public interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a document'
      And the thumbnail links to the Digital Object 'Report'

  Scenario: Without a Display Thumbnail on the Digital Object or its components no image or generic icon is shown
    Given a Digital Object 'Album' has been created without File Versions
      And the Digital Object 'Album' has a Digital Object Component 'Page' with the following File Versions
        | File       | Published | Marked as    | Caption |
        | a document | yes       | Display Link |         |
      And an Accession 'Donation' has been created with the Digital Object 'Album' as its representative instance
     When the user views the 'Donation' in the staff interface
     Then no thumbnail or generic icon is shown
     When the user views the 'Donation' in the public interface
     Then no thumbnail or generic icon is shown

  Scenario: A Digital Object instance that is not marked representative shows no image
    Given an Accession 'Donation' has been created with the Digital Object 'Photograph' as an instance that is not representative
     When the user views the 'Donation' in the staff interface
     Then no thumbnail or generic icon is shown
     When the user views the 'Donation' in the public interface
     Then no thumbnail or generic icon is shown
      And no IIIF viewer is embedded
