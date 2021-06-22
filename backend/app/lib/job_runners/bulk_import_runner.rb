# runs the bulk_importer

require_relative "../streaming_import"
require_relative '../ticker'

require_relative "../bulk_import/import_archival_objects"
require_relative "../bulk_import/import_digital_objects"
require "csv"

class BulkImportRunner < JobRunner
  register_for_job_type("bulk_import_job", :create_permissions => :import_records,
                                           :cancel_permissions => :cancel_importer_job,
                                           :allow_reregister => true)

  def run
    ticker = Ticker.new(@job)
    ticker.log("Start new bulk_import for job: #{@job.id}")
    last_error = nil
    # Wrap the import in a transaction if the DB supports MVCC
    begin
      DB.open(DB.supports_mvcc?,
              :retry_on_optimistic_locking_fail => true) do
        begin
          @input_file = @job.job_files[0].full_file_path
          @current_user = User.find(:username => @job.owner.username)
          @load_type = @json.job["load_type"]
          @validate_only = @json.job["only_validate"] == "true"
          params = parse_job_params_string(@json.job_params)
          params[:validate] = @validate_only
          ticker.log(("=" * 50) + "\n#{@json.job["filename"]}\n" + ("=" * 50))
          begin
            RequestContext.open(:create_enums => true,
                                :current_username => @job.owner.username,
                                :repo_id => @job.repo_id) do
              #               converter.run(@job[:job_blob])
              success = true
              importer = get_importer(@json.job["content_type"], params, ticker.method(:log))

              report = importer.run
              if !report.terminal_error.nil?
                msg = I18n.t("bulk_import.error.error", :term => report.terminal_error)
              else
                msg = I18n.t("bulk_import.processed")
              end
              ticker.log(msg)
              ticker.log(("=" * 50) + "\n")
              ticker.log(I18n.t(@validate_only ? "bulk_import.log_validation" : "bulk_import.log_complete", :file => @json.job["filename"]))
              ticker.log("\n" + ("=" * 50) + "\n")
              file = ASUtils.tempfile("load_spreadsheet_job_")
              generate_csv(file, report)
              file.rewind
              @job.write_output(I18n.t("bulk_import.log_results"))
              @job.add_file(file)
              @job.record_created_uris(importer.record_uris) unless @validate_only
            end
          end
        rescue JSONModel::ValidationException, BulkImportException => e
          last_error = e
        end
      end
    rescue
      last_error = $!
    end
    self.success!
    if last_error
      ticker.log("\n\n")
      ticker.log("!" * 50)
      ticker.log("IMPORT ERROR")
      ticker.log("!" * 50)
      ticker.log("\n\n")

      if last_error.respond_to?(:errors)
        ticker.log("#{last_error}") if last_error.errors.empty? # just spit it out if there's not explicit errors

        ticker.log("The following errors were found:\n")

        last_error.errors.each_pair { |k, v| ticker.log("\t#{k.to_s} : #{v.join(" -- ")}") }
      else
        ticker.log("Error: #{CGI.escapeHTML(last_error.inspect)}")
      end
      ticker.log("!" * 50)
      raise last_error
    end
  end

  private

  def generate_csv(file, report)
    headrow = I18n.t("bulk_import.clip_header").split("\t")
    CSV.open(file.path, "wb") do |csv|
      csv << Array.new(headrow)
      csv << []
      report.rows.each do |row|
        csvrow = [row.row]
        if row.archival_object_id.nil?
          if @load_type == "digital"
            csvrow = []
          else
            csvrow << I18n.t(@validate_only ? "bulk_import.error.no_ao_be" : "bulk_import.error.no_ao")
          end
        else
          if @load_type == "digital"
            csvrow << I18n.t("bulk_import.ao")
            csvrow << "#{row.archival_object_display}"
            csvrow << row.archival_object_id
            csvrow << "#{row.ref_id}"
          elsif @load_type == "ao"
            if @validate_only
              csvrow << I18n.t("bulk_import.object_created_be", :what => I18n.t("bulk_import.ao"))
              csvrow << row.archival_object_display
              csvrow << ""
              csvrow << ""
            else
              csvrow << ""
              csvrow << "#{row.archival_object_display}"
              csvrow << row.archival_object_id
              csvrow << "#{row.ref_id}"
            end
          end
        end
        csv << csvrow if !csvrow.empty?
        unless row.info.empty?
          row.info.each do |info|
            csvrow = Array.new(5, "")
            csvrow[0] = row.row
            csvrow << info
            csv << csvrow
          end
        end
        unless row.errors.empty?
          row.errors.each do |err|
            csvrow = Array.new(5, "")
            csvrow[0] = row.row
            csvrow << err
            csv << csvrow
          end
        end
      end
    end
  end

  def get_importer(content_type, params, log_method)
    importer = nil
    if @load_type == "digital"
      importer = ImportDigitalObjects.new(@input_file, content_type, @current_user, params, log_method)
    elsif @load_type == "ao"
      importer = ImportArchivalObjects.new(@input_file, content_type, @current_user, params, log_method)
    end
    importer
  end

end
