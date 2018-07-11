Customizing and Theming ArchivesSpace
==============================================================

While ArchivesSpace comes with a default look and feel for its interfaces, there are many ways the interfaces can be customized and themed according to your local preferences. Here are some of the general ways you can customize the interfaces, and typical approaches for each.

## Changing a few of the text labels or messages

All the messages and labels are stored in locales files, which is part of the [Rails Internationalization (I18n)](http://guides.rubyonrails.org/i18n.html) API. For example, a convention of the Rails framework stores all the English labels in a file called config/locales/en.yml.

You can see the source files for the
[ Staff Interface](https://github.com/archivesspace/archivesspace/tree/master/frontend/config/locales) and
[Public Interface](https://github.com/archivesspace/archivesspace/tree/master/public/config/locales),
as well as a [common locale file](https://github.com/archivesspace/archivesspace/blob/master/common/locales) for some values used throughout the ArchivesSpace application.

These values are pulled into the views using the I18n.t() method, like I18n.t("brand.welcome_message").

If the value you want to override is in the common locale file (like the "digital object title" field label, for example) , you can change this by simply editing the locales/en.yml file in your ArchivesSpace distribution home directory. A restart is required to have the changes take effect.  

If the value you want to override is in the public locale file (like the public interface welcome message, for example) , you can change this by simply editing the public/locales/en.yml file in your ArchivesSpace distribution home directory. A restart is required to have the changes take effect.  

If the value you want to change is in the frontend (staff interface) en.yml files, you can override these values using the plugins directory. For example, if you want to change the welcome message on the public frontend, make a file in your ArchivesSpace distribution called 'plugins/local/frontend/locales/en.yml' and put the following values:

    en:
     welcome:
     	heading: This is ArchivesSpace
     	message: Hey Hey Hey!!
     	message_logged_in: Yay! Yay! Yay!

If you restart ArchivesSpace, these values will take effect.

If you're using a different language, simply swap out the en.yml for something else ( like fr.yml ) and update the locale setting in the config.rb file ( i.e.,  AppConfig[:locale] = :fr )

## Changing the branding logo on the PUI

To change the branding logo on the public interface, open the config/config.rb file and set `AppConfig[:pui_branding_img]` to the name of the image file, along with the path `/assets/images/` you want to use as the branding logo. Then put a copy of the image in the directory plugins/local/public/assets/images.

Example:

`AppConfig[:pui_branding_img] = '/assets/images/logo.png'`

Restart the application and you should see your logo in the default view.

## Changing the branding logo on the PUI PDFs

To change the branding logo on the public interface print to PDF pages, create a directory at  `/local/public/views/pdf` put in the _titlepage.html.erb file and just change up the name of that default logo. Then put a copy of the new image in the directory `plugins/local/public/assets/images`. Be sure to change up `asset_path("archivesspace.small.png")` to match your new image name as well.

## Adding some CSS rules

Small CSS edits will be most easily done as a plugin. With a plugin, you can override default views, controllers, models, etc. without having to do a complete rebuild of the source code. You can customize CSS through the plugin system too. If you don't want to create a whole new plugin, the easiest way is to modify the 'local' plugin that ships with ArchivesSpace, which is intended for these kinds of site-specific changes. As long as you've still got 'local' listed in your AppConfig[:plugins] list, your changes will get picked up.

To do that, create a file called `archivesspace/plugins/local/frontend/views/layout_head.html.erb` for the staff side or `archivesspace/plugins/local/public/views/layout_head.html.erb` for the public. Then you can add the line to include the CSS in the site:

     <%= stylesheet_link_tag "#{@base_url}/assets/custom.css" %>

Then place your CSS in the file:

     staff side:
     archivesspace/plugins/local/frontend/assets/custom.css
     or public side:
     archivesspace/plugins/local/public/assets/custom.css

and it will get loaded on each page.

You may also want to make changes to the main index page, or the header and footer. Those overrides would go into the following places for the public side of your site:

    archivesspace/plugins/local/public/views/layouts/application.html.erb
    archivesspace/plugins/local/public/views/shared/_header.html.erb
    archivesspace/plugins/local/public/views/shared/_footer.html.erb

## Making complex changes and extensive theming for your site

Complex changes can also be made in a plugin using the override methods show above, but there are some big disadvantages to doing this in that way. The first is that assets will not be compiled by the Rails asset pipeline. Another is that you won't be able to take advantage of the variables and mixins that Bootstrap and Less provide as a framework, which really helps keep your assets well organized.

A better way to make complex theming changes is to pull down a copy of the ArchivesSpace code and build out a new theme. A good resource on how to do this is [this video](https://www.youtube.com/watch?v=Uny736mZVnk) .
This video covers the staff frontend UI, but the same steps can be applied to the public UI as well. You should also become a little familiar with the [build system instructions ](https://github.com/archivesspace/archivesspace/blob/master/build/BUILD_README.md)

First, pull down a new copy of ArchivesSpace using git and be sure to checkout a tag matching the version you're using or wanting to use.

     $ git clone https://github.com/archivesspace/archivesspace/blob/master/build/README.md
     $ git checkout v1.0.9

You can start your application development server by executing:

	     $ ./build/run bootstrap
	     $ ./build/run backend:devserver
	     $ ./build/run frontend:devserver
	     $ ./build/run public:devserver

( Note: you don't have to run all these commands all the time. The bootstrap command really only has to be run the first time your pull down the code..it will also take awhile.  You also don't have to start the frontend or public if you're not working on those interfaces. The backend does have to be started for either the public or frontend interfaces to work. )

Follow the instructions in the video to create a new theme. A good way is to copy the existing default theme to a new folder and start making your updates. Be sure to take advantage of the existing variables set in the Less files to keep your assets organized.

Once you've updated your theme and have it working, you can package your application. You can use the ./scripts/build_release to build a totally fresh AS distribution, but you don't need to do that if you've simply made some minor changes to the UI. Instead, use the "./build/run public:war " to compile your assets and package a war file. You can then take this public.war file and replace your ArchivesSpace distribution war file.

Be sure to update your theme setting in the config.rb file and restart ArchivesSpace.
