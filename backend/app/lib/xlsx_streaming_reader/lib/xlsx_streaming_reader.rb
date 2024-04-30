# The POI streaming XLSX reader is a *very* thin layer over the XML contained in
# the XLSX zip package.  This code is basically doing a SAX parse of the
# workbook.xml and sheet.xml files embedded in the XLSX.
#
# We tried several Ruby gems that handle XLSX files, but all of them had large
# memory footprints (https://github.com/roo-rb/roo/issues/179,
# https://github.com/weshatheleopard/rubyXL/issues/199,
# https://github.com/woahdae/simple_xlsx_reader/issues/25) when parsing large
# spreadsheets.  We would see memory usage of around 30-40x the size of the
# *uncompressed* xlsx file.
#
# This code runs in memory about 3x the size of the uncompressed content, and
# has a narrow enough interface to be easy to replace should a better option
# come along.
#
# The format we're dealing with pretty much looks like this:
#
#   <... outer stuff>
#     <row>
#       <c r="A1" t="n"><v>123</v></c><c r="B1" t="n"><v>456</v></c>
#     </row>
#     <row>
#       <c r="A2" t="n"><v>789</v></c><c r="B2" t="s"><v>hello</v></c>
#     </row>
#     ...
#   </outer stuff>
#
# Rows contain cells, cells contain values.  Types (t) are at the level of cells
# and can be numeric, strings, booleans, nulls, etc..  Each cell also has a
# reference (r) like 'A2'.
#
# Dates are stored as numbers of days since either 1899-12-30 OR 1904-01-01.
# You can tell whether a given cell is a date by looking at its style attribute
# (s).  You can tell which epoch scheme the spreadsheet uses by parsing the
# `date1904` property out of the workbook properties section.
#
# XLSX files are sparse, so empty/null cells are usually not stored.  See "Note
# on sparse cell storage" below for further explanation.

unless RUBY_PLATFORM == 'java'
  raise "xlsx_streaming_reader requires a JRuby runtime.  Cannot continue!"
end

Dir.glob(File.join(File.dirname(__FILE__), 'poi', '**/*.jar')).each do |jar|
  require File.absolute_path(jar)
end

class XLSXStreamingReader

  # The names of the different XML elements we'll be visiting
  ROW_ELEMENT = 'row'
  CELL_ELEMENT = 'c'
  VALUE_ELEMENT = 'v'
  FORMULA_ELEMENT = 'f'

  # The type codes of cells we'll be visiting
  STRING_TYPE = 's'
  NUMERIC_TYPE = 'n'
  BOOLEAN_TYPE = 'b'
  INLINE_STRING_TYPE = 'inlineStr'

  # The attributes of elements we'll need
  ATTRIBUTE_STYLE = 's'
  ATTRIBUTE_REFERENCE = 'r'
  ATTRIBUTE_TYPE = 't'

  class XLSXFileNotReadable < StandardError; end

  def initialize(filename)
    @filename = filename
  end

  def extract_workbook_properties(xssf_reader)
    workbook_properties = WorkbookPropertiesExtractor.new
    self.class.parse_with_handler(xssf_reader.get_workbook_data, workbook_properties)

    workbook_properties.properties
  end

  def extract_sheet_properties(xssf_reader)
    sheet_properties = WorkbookSheetsExtractor.new
    self.class.parse_with_handler(xssf_reader.get_workbook_data, sheet_properties)

    sheet_properties.sheets
  end

  def self.parse_with_handler(input_source, handler)
    parser = org.apache.poi.ooxml.util.SAXHelper.newXMLReader
    parser.set_content_handler(handler)

    parser.parse(org.xml.sax.InputSource.new(input_source))
  end

  def each(sheet_number = 0, &block)
    if block
      each_row(sheet_number, &block)
    else
      self.to_enum(:each_row, sheet_number)
    end
  end

  def each_row(sheet_specifier = 0, &block)
    begin
      pkg = org.apache.poi.openxml4j.opc.OPCPackage.open(@filename, org.apache.poi.openxml4j.opc.PackageAccess::READ)
      xssf_reader = org.apache.poi.xssf.eventusermodel.XSSFReader.new(pkg)
      workbook_properties = extract_workbook_properties(xssf_reader)

      sheet_properties = extract_sheet_properties(xssf_reader)

      sheet = if sheet_specifier.is_a?(Integer)
                sheet_number = sheet_specifier + 1
                xssf_reader.get_sheets_data.take(sheet_number).last
              elsif sheet_specifier.is_a?(String)
                # sheet_specifier is the name of the sheet
                matched_sheet = sheet_properties.find {|sheet| sheet.fetch('name').to_s.strip == sheet_specifier.strip}

                if !matched_sheet
                  raise "Couldn't find a sheet matching name '%s'" % [sheet_specifier.strip]
                end

                xssf_reader.get_sheet(matched_sheet.fetch('r:id'))
              else
                raise "Invalid sheet specifier: #{sheet_specifier}.  Needs to be an integer or a string."
              end

      begin
        self.class.parse_with_handler(sheet,
                                      SheetHandler.new(SharedStrings.new(xssf_reader.get_shared_strings_data),
                                                       xssf_reader.get_styles_table,
                                                       workbook_properties,
                                                       &block))
      ensure
        sheet.close
        pkg.close
      end
    rescue org.apache.poi.openxml4j.exceptions.NotOfficeXmlFileException,
           org.apache.poi.openxml4j.exceptions.InvalidFormatException,
           org.apache.poi.openxml4j.exceptions.ODFNotOfficeXmlFileException,
           org.apache.poi.openxml4j.exceptions.OLE2NotOfficeXmlFileException
      raise XLSXFileNotReadable.new(@filename)
    end
  end

  # XLSX files have an embedded sharedStrings.xml file that is a lookup table
  # mapping indexes to the original text content of the spreadsheet.  It's a
  # space-saving measure to avoid storing the same string bytes over and over.
  #
  # POI's sharedStringTable keeps a lot of stuff in memory that we don't care
  # about (we just want the text), so here's a simpler implementation.
  class SharedStrings
    STRING_ITEM_ELEMENT = 'si'
    TEXT_ELEMENT = 't'

    def initialize(stream)
      @strings = []
      if stream
        XLSXStreamingReader.parse_with_handler(stream, self)
      end
    end

    def get_item_at(n)
      @strings.fetch(n)
    end

    def method_missing(*)
    end

    def start_element(uri, local_name, name, attributes)
      if local_name.casecmp(STRING_ITEM_ELEMENT) == 0
        @item_strings = []
      elsif local_name.casecmp(TEXT_ELEMENT) == 0
        @value = ''
        @recording = true
      end
    end

    def characters(chars, start, length)
      if @recording
        @value += java.lang.String.new(chars, start, length)
      end
    end

    def end_element(uri, local_name, name)
      if local_name.casecmp(TEXT_ELEMENT) == 0
        @item_strings << @value
        @recording = false
      elsif local_name.casecmp(STRING_ITEM_ELEMENT) == 0
        @strings << @item_strings.join("")
      end
    end
  end


  class SheetHandler

    def initialize(string_table, style_table, workbook_properties, &block)
      @current_row = []
      @current_column = nil

      @value = ''
      @value_type_override = nil

      @string_table = string_table
      @style_table = style_table
      @workbook_properties = workbook_properties

      @row_handler = block
    end

    # Turn A into 1; Z into 26; AA into 27, etc.
    def col_reference_to_index(s)
      if s.empty?
        return 0
      end

      raise ArgumentError.new(s) unless s =~ /\A[A-Z]+\z/
      val = 0
      s.each_char do |ch|
        val *= 26
        val += (ch.ord - 'A'.ord) + 1
      end

      val
    end

    def start_element(uri, local_name, name, attributes)
      if local_name.casecmp(ROW_ELEMENT) == 0
        # New row
        @current_row = []
        @last_column = ''
      elsif local_name.casecmp(CELL_ELEMENT) == 0
        @value = ''

        # Note on sparse cell storage
        #
        # If we've skipped over columns since the last cell, we need to insert padding.
        #
        # This is because the spreadsheet doesn't contain entries for cells with
        # null values, so a spreadsheet with a value in column 1 and a value in
        # column 10 will contain only two cell entries, even though there are
        # conceptually 10 cells.  Those 8 null cells exist in our hearts and
        # minds, but not in the xlsx XML.
        current_column = attributes.getValue(ATTRIBUTE_REFERENCE).gsub(/[0-9]+/, '')

        # Calculate the number of columns between column refs like AA and AC
        gap = col_reference_to_index(current_column) - col_reference_to_index(@last_column)
        if gap > 1
          # Pad empty columns with nils
          @current_row.concat([nil] * (gap - 1))
        end

        @last_column = current_column

        # New cell
        case attributes.getValue(ATTRIBUTE_TYPE)
        when STRING_TYPE
          @value_type = :string
        when NUMERIC_TYPE, nil
          # A number can represent a date depending on the style of the cell.
          style_number = attributes.getValue(ATTRIBUTE_STYLE)
          style = !style_number.to_s.empty? && @style_table.getStyleAt(Integer(style_number))
          is_date = style && org.apache.poi.ss.usermodel.DateUtil.isADateFormat(style.get_data_format, style.get_data_format_string)

          if is_date
            @value_type = :date
          else
            @value_type = :number
          end
        when BOOLEAN_TYPE
          @value_type = :boolean
        when INLINE_STRING_TYPE
          @value_type = :inline_string
        else
          @value_type = :unknown
        end
      elsif local_name.casecmp(VALUE_ELEMENT) == 0 || local_name.casecmp(FORMULA_ELEMENT) == 0
        # New value within cell
        @reading_value = true
        @value = ''
      end
    end

    def end_element(uri, local_name, name)
      if local_name.casecmp(ROW_ELEMENT) == 0
        # Finished our row.  Yield it.
        @row_handler.call(@current_row)
      elsif local_name.casecmp(FORMULA_ELEMENT) == 0
        # @value contains the content of the formula.
        if ['TRUE()', 'FALSE()'].include?(@value)
          # Override the next value we read to be marked as a boolean.  Open
          # Office seems to (sometimes) express booleans as a formula rather
          # than as a cell type.
          @value_type_override = :boolean
        end
        @value = ''
        @reading_value = false
      elsif local_name.casecmp(VALUE_ELEMENT) == 0
        @reading_value = false
      elsif local_name.casecmp(CELL_ELEMENT) == 0
        # Finished our cell.  Process its value.
        parsed_value = case @value_type
                       when :string
                         if @value.to_s.empty?
                           ''
                         else
                           @string_table.get_item_at(Integer(@value))
                         end
                       when :number
                         if @value == ''
                           nil
                         elsif @value_type_override == :boolean
                           Integer(@value) == 1
                         else
                           begin
                             Integer(@value)
                           rescue ArgumentError
                             Float(@value)
                           end
                         end
                       when :date
                         if @value == ''
                           nil
                         else
                           value_int = Integer(@value)

                           epoch = is_boolean_true(@workbook_properties['date1904']) ?
                                     java.time.LocalDate.of(1904, 1, 1).atStartOfDay(java.time.ZoneId.systemDefault) :
                                     java.time.LocalDate.of(1899, 12, 30).atStartOfDay(java.time.ZoneId.systemDefault)

                           Time.at(epoch.plusDays(value_int).toEpochSecond)
                         end
                       when :boolean
                         @value != '0'
                       when :inline_string
                         @value.to_s
                       else
                         @value.to_s
                       end

        @value_type_override = nil
        @current_row << parsed_value
      end
    end

    def characters(chars, start, length)
      if @reading_value
        @value += java.lang.String.new(chars, start, length)
      end
    end

    def method_missing(*)
      # Don't care
    end

    def is_boolean_true(s)
      ['true', '1'].include?(s.to_s.strip.downcase)
    end
  end


  class WorkbookPropertiesExtractor
    def initialize
      @properties = {}
    end

    def method_missing(*)
      # Ignored
    end

    def start_element(uri, local_name, name, attributes)
      if local_name == 'workbookPr'
        attributes.getLength.times do |i|
          @properties[attributes.getName(i)] = attributes.getValue(i)
        end
      end
    end

    def properties
      @properties
    end
  end

  class WorkbookSheetsExtractor
    attr_reader :sheets

    def initialize
      @sheets = []
    end

    def method_missing(*)
      # Ignored
    end

    def start_element(uri, local_name, name, attributes)
      if local_name == 'sheet'
        sheet_properties = {}

        attributes.getLength.times do |i|
          sheet_properties[attributes.getName(i)] = attributes.getValue(i)
        end

        @sheets << sheet_properties
      end
    end
  end

end
