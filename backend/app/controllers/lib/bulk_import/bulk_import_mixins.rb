module BulkImportMixins

  # containes classes and methods that might be needed for more than one bulk import converter

  class BulkImportReport
    require 'pp'
    def initialize
      @rows = []
      @current_row = nil
      @terminal_error = ''
      @file_name = nil
      @error_rows = 0
    end

    def add_errors(errors)
      @error_rows += 1 if @current_row.errors.blank?
      @current_row.add_errors(errors)
    end

    def add_info(info)
      @current_row.add_info(info)
    end

    def add_archival_object(ao)
      @current_row.archival_object(ao) if ao
    end

    # If we stop processing before getting to the end of the spreadsheet, we want that reported out special
    def add_terminal_error(error, counter)
      if counter
        @terminal_error = I18n.t('plugins.aspace-import-excel.error.stopped', row: counter, msg: error)
      else
        @terminal_error = I18n.t('plugins.aspace-import-excel.error.initialize', msg: error)
      end
    end

    def row_count
      @rows.length
    end

    def end_row
      @rows.push @current_row if @current_row
      @current_row = nil
    end

    attr_reader :file_name

    def new_row(row_number)
      @rows.push @current_row if @current_row
      @current_row = Row.new(row_number)
    end

    def set_file_name(file_name)
      @file_name = file_name || I18n.t('plugins.aspace-import-excel.error.file_name')
    end

    attr_reader :rows

    attr_reader :terminal_error

    Row = Struct.new(:archival_object_id, :archival_object_display, :ref_id, :row, :errors, :info) do
      def initialize(row_number)
        self.row = I18n.t('plugins.aspace-import-excel.row', row: row_number)
        self.errors = []
        self.info = []
        self.archival_object_id = nil
        self.archival_object_display = nil
        self.ref_id = nil
      end

      # if other structures (top_container, agent, etc.) were created along the way
      def add_info(info)
        self.info.push info
      end

      def add_errors(errors)
        if errors.is_a? Array
          self.errors.concat(errors)
        else
          self.errors.push errors
        end
      end

      def archival_object(ao)
        self.archival_object_id = ao.uri
        self.archival_object_display = ao.display_string
        self.ref_id = ao.ref_id
      end
    end
  end
  
  # shamelessly stolen (and adapted) from HM's nla_staff_spreadsheet plugin :-)
  class ParentTracker
    require 'pp'
    def set_uri(hier, uri)
      @current_hierarchy ||= {}
      @current_hierarchy = Hash[@current_hierarchy.map {|k, v|
                                  if k < hier
                                    [k, v]
                                  end
                                }.compact]

      # Record the URI of the current record
      @current_hierarchy[hier] = uri
    end
    def parent_for(hier)
      # Level 1 parent may  be a resource record and therefore nil, 
      if hier > 0
        parent_level = hier - 1
        @current_hierarchy.fetch(parent_level)
      else
        nil
      end
    end
  end
end
