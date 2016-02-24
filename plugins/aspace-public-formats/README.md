Public Formats
=========

This plugin exposes additional output formats for resource and digital object records in the public interface. It provides a convenient way to retrieve EAD, MARCXML, DC (etc.) representations of ArchivesSpace objects without requiring a staff account or authenticated / direct access to the backend. Optionally links can be added to the navigation sidebar. 

Resources
-------------

- **EAD**
  - http://some.archivesspace.edu/repositories/2/resources/1/format/ead
- **HTML**
  - http://some.archivesspace.edu/repositories/2/resources/1/format/html
- **MARCXML**
  - http://some.archivesspace.edu/repositories/2/resources/1/format/marcxml
- **EAD-PDF**
  - http://some.archivesspace.edu/repositories/2/resources/1/format/ead_pdf

```
curl "http://localhost:8081/repositories/2/resources/1/format/ead"
```

Digital Objects
-------------------

- **Dublin Core**
  - http://some.archivesspace.edu/repositories/2/digital_objects/35/format/dc
- **METS**
  - http://some.archivesspace.edu/repositories/2/digital_objects/35/format/mets
- **MODS**
  - http://some.archivesspace.edu/repositories/2/digital_objects/35/format/mods

```
curl "http://localhost:8081/repositories/2/digital_objects/1/format/ead"
```

Configuration
------------------

By default links to the formats are **not** added to the navigation sidebar. To add links edit:

```
vi /path/to/archivesspace/config/config.rb
```

And set (choosing the options you want to create public links for):

```
AppConfig[:public_formats_resource_links] = ["ead", "marcxml", "ead_pdf"]
AppConfig[:public_formats_digital_object_links] = ["dc", "mets", "mods"]
```

HTML
--------

The HTML output works by first requesting the EAD, then performing an XSLT transform on the XML. There are a couple of additional requirements for the html output to work:

- clone the ead xslt repository from `https://github.com/tingletech/ead_basic_xslt`
- install xsltproc
- set the path to xsltproc and the xslt repository in `public/plugin_init.rb`

Compatibility
-----------------

- ArchivesSpace v1.1.1

---
