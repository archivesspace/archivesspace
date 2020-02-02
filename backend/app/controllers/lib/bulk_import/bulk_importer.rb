require_relative 'bulk_import_mixins'
require_relative 'agent_handler'
require_relative 'container_instance_handler'
require_relative 'digital_object_handler'
require_relative 'lang_handler'
require_relative 'notes_handler'
require_relative 'subject_handler'
require 'nokogiri'
require 'pp'
require 'rubyXL'
require 'asutils'

START_MARKER = /ArchivesSpace field code/.freeze
DO_START_MARKER = /ArchivesSpace digital object import field codes/.freeze

class BulkImporter

    def run
        Log.error('RUN')
        begin
            rows = initialize_info
            while @headers.nil? && (row = rows.next)
                @counter += 1
                if (row[0] && (row[0].value.to_s =~ @start_marker))
                    @headers = row_values(row)
                    Log.error("we have headers!")
                    begin
                    check_for_code_dups
                    rescue Exception => e
                    raise StopBulkImportException.new(e.message)
                    end
                    # Skip the human readable header too
                    rows.next
                    @counter += 1 # for the skipping
                end
            end
        rescue Exception => e
            if e.is_a?( BulkImportException) || e.is_a?( StopBulkImportException)
            @report.add_terminal_error(I18n.t('bulk_import.error.excel', :errs => e.message), @counter)
            elsif e.is_a?(StopIteration) && @headers.nil?
            @report.add_terminal_error(I18n.t('bulk_import.error.no_header'), @counter)
            else # something else went wrong
            @report.add_terminal_error(I18n.t('bulk_import.error.system', :msg => e.message), @counter)
            Log.error("UNEXPECTED EXCEPTION on bulkimport load! #{e.message}")
            Log.error( e.backtrace.pretty_inspect[0])
            end
        end
        return @report
    end
    

    def initialize(input_file, opts = {}, current_user)
        @input_file = input_file
#        @batch = ASpaceImport::RecordBatch.new
        @opts = opts
        Log.error("OPTS: #{@opts}")
        @current_user = current_user
        @report_out = []
        @report = BulkImportReport.new
        @headers
        @digital_load  = @opts.fetch(:digital_load,'') == 'true'
    
        if @digital_load
          @find_uri =  "/repositories/#{@opts[:repo_id]}/find_by_id/archival_objects"
          @resource_ref = "/repositories/#{@opts[:repo_id]}/resources/#{@opts[:id]}"
          @repo_id = @opts[:repo_id]
          @start_marker = DO_START_MARKER
        else
          @created_ao_refs = []
          @first_level_aos = []
          @archival_levels = CvList.new('archival_record_level', @current_user)
          @container_types = CvList.new('container_type', @current_user)
          @date_types = CvList.new('date_type', @current_user)
          @date_labels = CvList.new('date_label', @current_user)
          @date_certainty = CvList.new('date_certainty', @current_user)
          @extent_types = CvList.new('extent_extent_type', @current_user)
          @extent_portions = CvList.new('extent_portion', @current_user)
          @instance_types ||= CvList.new('instance_instance_type', @current_user)
          @parents = ParentTracker.new
          @start_marker = START_MARKER
        end
        @start_position
        @need_to_move = false
        # WAAY more initialization to come
      end
      # this refreshes the controlled list enumerations, which may have changed since the last import
      def initialize_handler_enums
        cih = ContainerInstanceHandler(@current_user)
        doh = DigitalObjectHandler(@current_user)
        sh = SubjectHandler(@current_user)
        ah = AgentHandler(@current_user)
        lh = LangHandler(@current_user)
      end
      
      private
    
      def check_for_code_dups
        test = {}
        dups = ""
        @headers.each do |head|
          if test[head]
            dups = "#{dups} #{head},"
          else
            test[head] = true
          end
        end
        if !dups.empty?
          raise Exception.new( I18n.t('bulk_import.error.duplicates', :codes => dups))
        end
      end
    
      # set up all the @ variables (except for @header)
      def initialize_info
        @orig_filename = @opts[:filename]
        @report_out = []
        @report = BulkImportTracker.new
        @headers
        @digital_load = @opts[:digital_load] == 'true'
        @report.set_file_name(@orig_filename)
        # initialize_handler_enums
        @resource = Resource.get_or_die(@opts[:rid])
        Log.error("BulkImport got resource: #{@resource.inspect}")
        Log.error("BulkImport repo_id match? #{@opts[:repo_id] == @resouce[:repo_id]}")
        @repository = Repository.get_or_die(@opts[:repo_id])
        Log.error("BulkImport got repo: #{@repository.inspect}")
        @hier = 1
        unless @digital_load
          @ao = nil
          aoid = @opts[:aoid] || nil
          @resource_level = aoid.nil?
          @first_one = false # to determine whether we need to worry about positioning
          if @resource_level
            @parents.set_uri(0, nil)
            @hier = 0
          else
            @ao = JSONModel(:archival_object).find(aoid, find_opts)
            Log.error("Archival Object found: #{@ao.pretty_inspect}")
            @start_position = @ao.position
            parent = @ao.parent # we need this for sibling/child disabiguation later on
            @parents.set_uri(0, (parent ? ASUtils.jsonmodels_to_hashes(parent)['ref'] : nil))
            @parents.set_uri(1, @ao.uri)
            @first_one = true
          end
        end
        @input_file = dispatched_file_path
        @counter = 0
        @rows_processed = 0
        @error_rows = 0
        Log.error("About to open #{@input_file}")
        workbook = RubyXL::Parser.parse(@input_file)
        Log.error('Got workbook ')
        sheet = workbook[0]
        Log.error('Got sheet: ')
        rows = sheet.enum_for(:each)
      end
    
      def row_values(row)
        (1...row.size).map {|i| (row[i] && row[i].value) ? (row[i].value.to_s.strip.empty? ? nil : row[i].value.to_s.strip) : nil}
      end
end