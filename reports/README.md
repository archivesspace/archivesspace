Report Assets
-------------

## Using a custom font for PDF reports

ArchivesSpace uses the public domain font `Deja Vu` when rendering PDF reports.  While this font offers a good
coverage of Unicode characters, you may wish to use your own licenced font for a greater coverage.

To configure your own font:

1. Under your `archivesspace` directory add your `ttf` font to the `reports/static/fonts` directory

2. In the `config/config.rb`, modify the following configuration settings to refer to your new font:

        AppConfig[:report_pdf_font_paths] = proc { ["#{AppConfig[:backend_url]}/reports/static/fonts/myfont.ttf"] }
        AppConfig[:report_pdf_font_family] = "My Font"

3. Restart your application for the new configuration settings to apply.

## Including Jasper JRXML Files for reports

Add your JRXML file to the jasper directory.

