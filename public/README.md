The ArchivesSpace Public User Interface
=======================================

The ArchivesSpace Public User Interface (PUI) provides a public
interface to your ArchivesSpace collections.  In a default
ArchivesSpace installation it runs on port `:8081`.

# Configuration

The PUI is configured using the standard ArchivesSpace `config.rb`
file, with the relevant configuration options are prefixed with
`:pui_`.

To see the full list of available options, see the file
[`../common/config/config-defaults.rb`](../common/config/config-defaults.rb)

## robots.txt
The default, the robots.txt file packaged in public.war file is open to the world so that it will be indexed by Google and other search sites. If you wish to restrict web spiders from crawling all or part of your public site, you can replace this file in the warfile with the command: `zip -uj archivesspace/wars/public.war  robots.txt`, or if you include a robots.txt file in the archivesspace/config directory, it will be used to replace the one packaged in the war file on startup.

See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file

## Preserving Patron Privacy

The **:block_referrer** key in the configuration file (default: **true**) determines whether the full referring URL is
transmitted when the user clicks a link to a website outside the web domain of your instance of ArchivesSpace.  This
protects your patrons from tracking by that site.

## Main Navigation Menu

You can choose not to display one or more of the links on the main
(horizontal) navigation menu, either globally or by repository, if you
have more than one repository.  You manage this through the
`:pui_hide` options in the `config/config.rb` file.

## Repository Customization

### Display of "badges" on the Repository page

You can configure which badges appear on the Repository page, both
globally or by repository.  See the `:pui_hide` configuration options
for these too.

## Activation of the "Request" button on archival object pages

You can configure, both globally or by repository, whether the
"Request" button is active on archival object pages for objects that
don't have an associated Top Container.  See the
`:pui_requests_permitted_for_containers_only` configuration option to
modify this.

## I18n

You can change the text and labels used by the PUI by editing the
locale files under the `locales/public` directory of your
ArchivesSpace distribution.

## Addition of a "lead paragraph"

You can also use the custom `.yml` files, described above, to add a
custom "lead paragraph" (including html markup) for one or more of
your repositories, keyed to the repository's code.

For example, if your repository, `My Wonderful Repository` has a code of `MWR`, this is what you might see in the
custom `en.yml`:
```
en:
  repos:
    mwr:
      lead_graph: This <strong>amazing</strong> repository has so much to offer you!
```

# Development

To run a development server, the PUI follows the same pattern as the rest of ArchivesSpace.  From your ArchivesSpace checkout:

     # Prepare all dependencies
     build/run bootstrap

     # Run the backend development server (and Solr)
     build/run backend:devserver

     # Run the indexer
     build/run indexer

     # Finally, run the PUI itself
     build/run public:devserver

## Inheritance

### Three options for inheritance:

* Directly inherit a value for a field – the record has no value for the field and you want the value in the field to display as if it were the record’s own [uncomment the inheritance section in the config, set desired field (property) to inherit_directly => true]

* Indirectly inherit a value for a field – the record has no value for the field and you want to display the value from a higher level, but precede it with a note that indicates that it comes from that higher level, such as “From the collection” [uncomment the inheritance section in the config, set desired field (property) to inherit_directly => false]

* Don’t display the field at all – the record has no value of its own for the field and you don’t want it to display at all [uncomment the inheritance section in the config, delete the lines for the desired field (property)]


### Archival Inheritance

With the new version of the Public Interface, all elements of description can be inherited. This is especially important since the PUI displays each level of description as its own webpage.

Each element of description can be inherited either directly or indirectly. When an element is inherited directly, it will appear as if that element was attached directly to that archival object in the staff interface. When an element is inherited indirectly, it will appear on the lower-level of description in the public interface, but the inherited element will be preceded with a note indicating the level of the ancestor from which the note is inherited (e.g. From the Collection, or From the Sub-Series). In both cases, the element will only be inherited if it is missing from the archival object. Additionally, the element of description will only be inherited from the closest ancestor. In other words, if a top-level collection record has an access restrictions note, and a child-level series record has an an access restrictions note, but the sub-series child of that series record lacks an access restrictions note, then the sub-series record will inherit only the access restrictions note from its parent series record.

Additionally, the identifier element in ArchivesSpace, which is better known as the Reference Code in ISAD-G and DACS, can be inherited in a composite manner. When inherited in a composite manner, the inherited elements will be concatenated together. In other words, an identifier at the item level could look like this: MSS 1. Series A. Item 1. Though the archival object has an identifier of “Item 1”, a composite identifier is displayed since the series-level record to which the item belongs has an identifier of "Series A”, which in turn also belongs to a collection-level record that has an identifier of “MSS 1”.

By default, the following elements are turned on for inheritance:

· Title (direct inheritance)

· Identifier (indirect inheritance, but by default the identifier inherits from ancestor archival objects only; it does NOT include the resource identifier.

Also it is advised to inherit this element in a composite fashion once it is determined whether the level of description should or should not display as part of the identifier, which will depend upon local data-entry practices

· Language code (direct inheritance, but it does NOT display anywhere in the interface currently; eventually, this could be used for faceting)

· Dates (direct inheritance)

· Extents (indirect inheritance)

· Creator (indirect inheritance)

· Access restrictions note (direct inheritance)

· Scope and contents note (indirect inheritance)

· Language of Materials note (indirect inheritance, but there seems to be a bug right now so that the Language notes always show up as being directly inherited. See AR-XXXX)

See https://github.com/archivesspace/archivesspace/blob/master/common/config/config-defaults.rb#L296-L396 for more information and examples.

Also, a video overview of this feature, which was recorded before development was finished, is available online:
https://vimeo.com/195457286

Composite Identifier Inheritance

If you add the following three lines to your configuration file, re-start ArchivesSpace, and then let the indexer re-index your records, you can gain the benefit of composite identifiers:

```
AppConfig[:record_inheritance][:archival_object][:composite_identifiers] = {
:include_level => true,
:identifier_delimiter => '. '
}
```

To add extra fields, such as subjects you can add the following:

```
inherited_fields_extras = [
  {
    code: 'subjects',
    property: 'subjects',
    inherit_if: proc { |json| json.select { |j| true } },
    inherit_directly: false,
  },
]
```

When you set include_level to true, that means that the archival object level will be included in identifier so that you don't have to repeat that data. For example, if the level of description is "Series" and the archival object identifier is "1", and the parent resource identifier is "MSS 1", then the composite identifier would display as "MSS 1. Series 1" at the series 1 level, and any descendant record. If you set include_level to false, then the display would be "MSS 1. 1"

## License

ArchivesSpace is released under the [Educational Community License,
version 2.0](http://opensource.org/licenses/ecl2.php). See the
[COPYING](COPYING) file for more information.
