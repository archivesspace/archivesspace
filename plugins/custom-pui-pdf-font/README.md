# Custom PUI PDF Fonts

This plugin enables the use of custom fonts in the PDF finding aids generated in the PUI.

To use, copy your TTF font files in the public/app/assets/fonts/ directory in the plugin.

Then, update your config.rb file. For example:

AppConfig[:plugins] = ['local', 'lcnaf', 'custom-pui-pdf-font']
AppConfig[:pui_pdf_font_files] = ["KurintoText-Rg.ttf",
                                  "NotoSerif-Regular.ttf"]

AppConfig[:pui_pdf_font_name] = "Unifont, Noto Serif"

This will enable the use of the "GNU Unifont" font included in this plugin, which has glyphs for all possible Unicode characters, with Noto Serif as a backup.

Please note, using this plugin will overwrite the default PUI PDF font files used by ArchivesSpace, and if your file or font names are incorrect, the PUI PDFs will not render properly, if at all.

Also note that many fonts have bold and italic glyphs in separate font files, and these will each need to be loaded.
