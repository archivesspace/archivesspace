# runs the bulk_importer

require_relative "../streaming_import"
require_relative "../bulk_import/import_archival_objects"
require_relative "../bulk_import/import_digital_objects"

class Ticker
  def initialize(job)
    @job = job
    Log.error("TICKER #{@job.inspect}")
  end

  def tick
  end

  def status_update(status_code, status)
    @job.write_output("#{status[:id]}. #{status_code.upcase}: #{status[:label]}")
  end

  def log(s)
    @job.write_output(s)
  end

  def tick_estimate=(n)
  end
end

class BulkImportRunner < JobRunner
  register_for_job_type("bulk_import_job", :create_permissions => :import_records,
                                           :cancel_permissions => :cancel_importer_job, :hidden => true)

  def run
    ticker = Ticker.new(@job)
    ticker.log("Start new bulk_import ")
    ticker.log(@json.job.inspect)
    last_error = nil
    batch = nil
    success = false
    jobfiles = @job.job_files || []
    Log.error("job files? #{jobfiles.inspect}")
    filenames = [@json.job["file_name"]]
    # Wrap the import in a transaction if the DB supports MVCC
    begin
      DB.open(DB.supports_mvcc?,
              :retry_on_optimistic_locking_fail => true) do
        begin
          @input_file = @job.job_files[0].full_file_path
          @current_user = User.find(:username => @job.owner.username)
          # I don't know whay this parsing is so hard!!
          param_string = @json.job_params[1..-2].delete('\\\\')
          params = ASUtils.json_parse(param_string)
          params = symbol_keys(params)
          ticker.log(params.inspect)
          ticker.log(("=" * 50) + "\n#{@json.job["filename"]}\n" + ("=" * 50))
          begin
            RequestContext.open(:create_enums => true,
                                :current_username => @job.owner.username,
                                :repo_id => @job.repo_id) do
              #               converter.run(@job[:job_blob])
              success = true
              importer = get_importer(params)

              report = importer.run
              if !report.terminal_error.nil?
                msg = I18n.t("bulk_import.error.error", :term => report.terminal_error)
              else
                msg = I18n.t("bulk_import.processed")
              end
              ticker.log(msg)
              ticker.log(("=" * 50) + "\n")
              ticker.log(process_report(report))

              ticker.log("\n" + ("=" * 50) + "\n")
            end
          end
        rescue JSONModel::ValidationException, BulkImportException, Sequel::ValidationFailed, ReferenceError => e
          # Note: we deliberately don't catch Sequel::DatabaseError here.  The
          # outer call to DB.open will catch that exception and retry the
          # import for us.
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

        if last_error.is_a?(Sequel::ValidationFailed)
          ticker.log("\n")
          ticker.log("%" * 50)
          ticker.log("\n Full Error Message:\n #{last_error.to_s}\n\n")
        end

        if (last_error.respond_to?(:invalid_object) && last_error.invalid_object)
          ticker.log("\n\n For #{last_error.invalid_object.class}: \n #{last_error.invalid_object.inspect}")
        end

        if (last_error.respond_to?(:import_context) && last_error.import_context)
          ticker.log("\n\nIn : \n #{CGI.escapeHTML(last_error.import_context)} ")
          ticker.log("\n\n")
        end
      else
        ticker.log("Error: #{CGI.escapeHTML(last_error.inspect)}")
        Log.exception(last_error)
      end
      ticker.log("!" * 50)
      raise last_error
    end
  end

  private

  def get_importer(params)
    # TODO: replace digital_load key with
    # TODO: replace file_type with content_type
    @dig_o = params.fetch(:digital_load) == "true"
    importer = nil
    if @dig_o
      importer = ImportDigitalObjects.new(@input_file, params.fetch(:file_type), @current_user, params)
    else
      importer = ImportArchivalObjects.new(@input_file, params.fetch(:file_type), @current_user, params)
    end
    importer
  end

  def process_report(report)
    output = ""
    report.rows.each do |row|
      output += row.row
      if row.archival_object_id.nil?
        output += " " + I18n.t("bulk_import.no_ao") if !@dig_o
      else
        if @dig_o
          output += I18n.t("bulk_import.clip_what", :what => I18n.t("bulk_import.ao"), :id => row.archival_object_id,
                                                    :nm => "'#{row.archival_object_display}'",
                                                    :ref_id => "#{row.ref_id}")
        else
          output += I18n.t("bulk_import.clip_created", :what => I18n.t("bulk_import.ao"), :id => row.archival_object_id,
                                                       :nm => "'#{row.archival_object_display}'",
                                                       :ref_id => "#{row.ref_id}")
        end
      end
      output += "\n"
      unless row.info.empty?
        row.info.each do |info|
          output += I18n.t("bulk_import.clip_info", :what => info) + "\n"
        end
      end
      unless row.errors.empty?
        row.errors.each do |err|
          output += I18n.t("bulk_import.clip_err", :err => err) + "\n"
        end
      end
    end
    output
  end

  def symbol_keys(hash)
    h = hash.map do |k, v|
      v_sym = if v.instance_of? Hash
          v = symbol_keys(v)
        else
          v
        end

      [k.to_sym, v_sym]
    end
    Hash[h]
  end
end
