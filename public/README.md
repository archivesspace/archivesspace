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
[`app/archivesspace-public/app/lib/config_defaults.rb`](app/archivesspace-public/app/lib/config_defaults.rb)

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

## License

ArchivesSpace is released under the [Educational Community License,
version 2.0](http://opensource.org/licenses/ecl2.php). See the
[COPYING](COPYING) file for more information.
