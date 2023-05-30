# Custom PUI PDF Fonts

This plugins enables the use of custom fonts in the PDF finding aids generated in the PUI.

To use, copy your TTF font file in the public/app/assets/fonts/ directory in the plugin.

Then, update your config.rb file. For example:

AppConfig[:plugins] = ['local', 'lcnaf', 'custom-pui-pdf-font']
AppConfig[:pui_pdf_font_file] = "unifont-15.0.01.ttf"
AppConfig[:pui_pdf_font_name] = "Unifont"

This will enable the use of the "GNU Unifont" font included in this plugin, which has glyphs for all possible Unicode characters.

