---
title: ArchivesSpace Plug-ins
layout: en
permalink: /user/archivesspace-plug-ins/
---
Plug-ins are a powerful feature, designed to allow you to change
most aspects of how the application behaves.

Plug-ins provide a mechanism to customize ArchivesSpace by overriding or extending functions
without changing the core codebase. As they are self-contained, they also permit the ready
sharing of packages of customization between ArchivesSpace instances.

The ArchivesSpace distribution comes with the `hello_world` exemplar plug-in. Please refer to its [README file](https://github.com/archivesspace/archivesspace/blob/master/plugins/hello_world/README.md) for a detailed description of how it is constructed and implemented.

## Enabling plugins

Plug-ins are enabled by placing them in the `plugins` directory, and referencing them in the
ArchivesSpace configuration, `common/config/config.rb`. For example:

    AppConfig[:plugins] = ['local', 'hello_world', 'my_plugin']

This configuration assumes the following directories exist:

    plugins
      hello_world
      local
      my_plugin

Note that the order that the plug-ins are listed in the `:plugins` configuration option
determines the order in which they are loaded by the application.

## Plugin structure

The directory structure within a plug-in is similar to the structure of the core application.
The following shows the supported plug-in structure. Files contained in these directories can
be used to override or extend the behavior of the core application.

    backend
      controllers ......... backend endpoints
      model ............... database mapping models
      converters .......... classes for importing data
      job_runners ......... classes for defining background jobs
      plugin_init.rb ...... if present, loaded when the backend first starts
    frontend
      assets .............. static assets (such as images, javascript) in the staff interface
      controllers ......... controllers for the staff interface
      locales ............. locale translations for the staff interface
      views ............... templates for the staff interface
      plugin_init.rb ...... if present, loaded when the staff interface first starts
    public
      assets .............. static assets (such as images, javascript) in the public interface
      controllers ......... controllers for the public interface
      locales ............. locale translations for the public interface
      views ............... templates for the public interface
      plugin_init.rb ...... if present, loaded when the public interface first starts
    migrations ............ database migrations
    schemas ............... JSONModel schema definitions
    search_definitions.rb . Advanced search fields

**Note** that, in order to override or extend the behavior of core models and controllers, you cannot simply put your replacement with the same name in the corresponding directory path.  Core models and controllers can be overridden by adding an `after_initialize` block to `plugin_init.rb` (e.g. [aspace-hvd-pui](https://github.com/harvard-library/aspace-hvd-pui/blob/master/public/plugin_init.rb#L43)).

## Overriding behavior

A general rule is: to override behavior, rather then extend it, match the path
to the file that contains the behavior to be overridden.

It is not necessary for a plug-in to have all of these directories. For example, to override
some part of a locale file for the staff interface, you can just add the following structure
to the local plug-in:

    plugins/local/frontend/locales/en.yml

More detailed information about overriding locale files is found in [Customizing text in ArchivesSpace](https://archivesspace.github.io/archivesspace/user/customizing-text-in-archivesspace/)


## Overriding the visual (web) presentation

You can directly override any view file in the core application by placing an erb file of the same name in the analogous path.
For example, if you want to override the appearance of the "Welcome" [home] page of the Public User Interface, you can make your changes to a file `show.html.erb` and place it at `plugins/my_fine_plugin/public/views/welcome/show.html.erb`. (Where *my_fine_plugin* is the name of your plugin)

### Implementing a broadly-applied style or javascript change

Unless you want to write inline style or javascript (which may be practiceable for a template or two), best practice is to create `plugins/my_fine_plugin/public/views/layout_head.html.erb` or `plugins/my_fine_plugin/frontend/views/layout_head.html.erb`, which contains the HTML statements to incorporate your javascript or css into the `<HEAD>` element of the template.  Here's an example:

* For the public interface, I want to change the size of the text in all links when the user is hovering.
    - I create `plugins/my_fine_plugin/public/assets/my.css`:
        ```css
            a:hover {font-size: 2em;}
         ```
    - I create `plugins/my_fine_plugin/public/views/layout_head.html.erb`, and insert:
      ```ruby
      <%= stylesheet_link_tag "#{@base_url}/assets/my.css", media: :all %>
      ```
* For the public interface, I want to add some javascript behavior such that, when the user hovers over a list item, astericks appear
    - I create `plugins/my_fine_plugin/public/assets/my.js`"
        ```javascript
        $(function() {
           $( "li" ).hover(
             function() {
                $( this ).append( $( "<span> ***</span>" ) );
            }, function() {
           $( this ).find( "span:last" ).remove();
            }
          );
         }
        ```
     - I add to `plugins/my_fine_plugin/public/views/layout_head.html.erb`:
        ```ruby
        <%= javascript_include_tag "#{@base_url}/assets/my.js" %>
        ```
## Adding your own branding


Another example, to override the branding of the staff interface, add
your own template at:

    plugins/local/frontend/views/site/\_branding.html.erb

Files such as images, stylesheets and PDFs can be made available as static resources by
placing them in an `assets` directory under an enabled plug-in. For example, the following file:

    plugins/local/frontend/assets/my_logo.png

Will be available via the following URL:

    http://your.frontend.domain.and:port/assets/my_logo.png

For example, to reference this logo from the custom branding file, use
markup such as:

     <div class="container branding">
       <img src="<%= #{AppConfig[:frontend_proxy_prefix]} %>assets/my_logo.png" alt="My logo" />
     </div>


## Plugin configuration

Plug-ins can optionally contain a configuration file at `plugins/[plugin-name]/config.yml`.
This configuration file supports the following options:

    system_menu_controller
      The name of a controller that will be accessible via a Plug-ins menu in the System toolbar
    repository_menu_controller
      The name of a controller that will be accessible via a Plug-ins menu in the Repository toolbar
    parents
      [record-type]
        name
        cardinality
      ...

`system_menu_controller` and `repository_menu_controller` specify the names of frontend controllers
that will be accessible via the system and repository toolbars respectively. A `Plug-ins` dropdown
will appear in the toolbars if any enabled plug-ins have declared these configuration options. The
controller name follows the standard naming conventions, for example:

    repository_menu_controller: hello_world

Points to a controller file at `plugins/hello_world/frontend/controllers/hello_world_controller.rb`
which implements a controller class called `HelloWorldController`. When the menu item is selected
by the user, the `index` action is called on the controller.

Note that the URLs for plug-in controllers are scoped under `plugins`, so the URL for the above
example is:

    http://your.frontend.domain.and:port/plugins/hello_world

Also note that the translation for the plug-in's name in the `Plug-ins` dropdown menu is specified
in a locale file in the `frontend/locales` directory in the plug-in. For example, in the `hello_world`
example there is an English locale file at:

    plugins/hello_world/frontend/locales/en.yml

The translation for the plug-in name in the `Plug-ins` dropdown menus is specified by the key `label`
under the plug-in, like this:

    en:
      plugins:
        hello_world:
          label: Hello World

Note that the example locale file contains other keys that specify translations for text displayed
as part of the plug-in's user interface. Be sure to place your plug-in's translations as shown, under
`plugins.[your_plugin_name]` in order to avoid accidentally overriding translations for other
interface elements. In the example above, the translation for the `label` key can be referenced
directly in an erb view file as follows:

    <%= I18n.t("plugins.hello_world.label") %>

Each entry under `parents` specifies a record type that this plug-in provides a new subrecord for.
`[record-type]` is the name of the existing record type, for example `accession`. `name` is the
name of the plug-in in its role as a subrecord of this parent, for example `hello_worlds`.
`cardinality` specifies the cardinality of the plug-in records. Currently supported values are
`zero-to-many` and `zero-to-one`.


## Changing search behavior

A plugin can add additional fields to the advanced search interface by
including a `search_definitions.rb` file at the top-level of the
plugin directory.  This file can contain definitions such as the
following:

    AdvancedSearch.define_field(:name => 'payment_fund_code', :type => :enum, :visibility => [:staff], :solr_field => 'payment_fund_code_u_utext')
    AdvancedSearch.define_field(:name => 'payment_authorizers', :type => :text, :visibility => [:staff], :solr_field => 'payment_authorizers_u_utext')

Each field defined will appear in the advanced search interface as a
searchable field.  The `:visibility` option controls whether the field
is presented in the staff or public interface (or both), while the
`:type` parameter determines what sort of search is being performed.
Valid values are `:text:`, `:boolean`, `:date` and `:enum`.  Finally,
the `:solr_field` parameter controls which field is used from the
underlying index.

## Adding Custom Reports

Custom reports may be added to plug-ins by adding a new report model as a subclass of `AbstractReport` to `plugins/[plugin-name]/backend/model/`, and the translations for said model to `plugins/[plugin-name]/frontend/locales/[language].yml`. Look to existing reports in reports subdirectory of the ArchivesSpace base directory for examples of how to structure a report model.

There are several limitations to adding reports to plug-ins, including that reports from plug-ins may only use the generic report template. ArchivesSpace only searches for report templates in the reports subdirectory of the ArchivesSpace base directory, not in plug-in directories. If you would like to implement a custom report with a custom template, consider adding the report to `archivesspace/reports/` instead of `archivesspace/plugins/[plugin-name]/backend/model/`.


## Frontend Specific Hooks

To make adding new records fields and sections to record forms a little eaiser via your plugin, the ArchivesSpace frontend provides a series of hooks via the `frontend/config/initializers/plugin.rb` module. These are as follows:

* `Plugins.add_search_base_facets(*facets)` - add to the base facets list to include extra facets for all record searches and listing pages.

* `Plugins.add_search_facets(jsonmodel_type, *facets)` - add facets for a particular JSONModel type to be included in searches and listing pages for that record type.

* `Plugins.add_resolve_field(field_name)` - use this when you have added a new field/relationship and you need it to be resolved when the record is retrieved from the API.

* `Plugins.register_edit_role_for_type(jsonmodel_type, role)` - when you add a new top level JSONModel, register it and its edit role so the listing view can determine if the "Edit" button can be displayed to the user.

* `Plugins.register_note_types_handler(proc)` where proc handles parameters `jsonmodel_type, note_types, context` - allow a plugin to customize the note types shown for particular JSONModel type. For example, you can filter those that do not apply to your institution.

* `Plugins.register_plugin_section(section)` - allows you define a template to be inserted as a section for a given JSONModel record. A section is a type of `Plugins::AbstractPluginSection` which defines the source `plugin`, section `name`, the `jsonmodel_types` for which the section should show and any `opts` required by the templates at the time of render. These new sections (readonly, edit and sidebar additions) are output as part of the `PluginHelper` render methods.

  `Plugins::AbstractPluginSection` can be subclassed to allow flexible inclusion of arbitrary HTML. There are two examples provided with ArchivesSpace:

  * `Plugins::PluginSubRecord` - uses the `shared/subrecord` partial to output a standard styled ArchivesSpace section. `opts` requires the jsonmodel field to be defined.

  * `Plugins::PluginReadonlySearch` - uses the `search/embedded` partial to output a search listing as a section. `opts` requires the custom filter terms for this search to be defined.

## Further information

**Be sure to test your plug-in thoroughly as it may have unanticipated impacts on your
ArchivesSpace application.**
