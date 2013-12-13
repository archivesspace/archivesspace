Dir.glob(File.expand_path("../converters/*.rb", File.dirname(__FILE__))).sort.each do |converter|
  require converter
end

require_relative 'streaming_import'


class Ticker

  def initialize(job)
    @job = job
    @estimate = nil
    @ticks = 0
  end


  def tick
    @ticks += 1

    if @estimate && (@ticks % 100) == 0
      percent = ([@ticks, @estimate].min.to_f / @estimate) * 100
      @job.write_output("Percent completed: #{percent.round(2)}%")
    end
  end


  def status_update(status_code, status)
    @job.write_output("#{status[:id]}. #{status_code.upcase}: #{status[:label]}")
  end


  def log(s)
    @job.write_output(s)
  end


  def tick_estimate=(n)
    @estimate = n
  end
end


class BatchImportRunner

  def initialize(job)
    @job = job
  end


  def run
    ticker = Ticker.new(@job)

    last_error = nil
    batch = nil
    success = false

    # Wrap the import in a transaction if the DB supports MVCC
    begin
      DB.open(DB.supports_mvcc?,
              :retry_on_optimistic_locking_fail => true) do

        begin
          @job.job_files.each do |input_file|
            converter = Converter.for(@job.import_type, input_file.file_path)
            begin
              converter.run

              File.open(converter.get_output_path, "r") do |fh|
                RequestContext.open(:create_enums => true,
                                    :current_username => @job.owner.username,
                                    :repo_id => @job.repo_id) do
                  batch = StreamingImport.new(fh, ticker)
                  batch.process
                  success = true
                end
              end
            ensure
              converter.remove_files
            end
          end
        rescue JSONModel::ValidationException, ImportException, Sequel::ValidationFailed, ReferenceError => e
          # Note: we deliberately don't catch Sequel::DatabaseError here.  The
          # outer call to DB.open will catch that exception and retry the
          # import for us.
          last_error = e

          # Roll back the transaction (if there is one)
          raise Sequel::Rollback
        end
      end
    rescue
      last_error = $!
    ensure
      # If we were running in a transaction, the whole batch will have been
      # rolled back.
      batch = nil if !success && DB.supports_mvcc?
    end

    results = {:saved => []}

    if batch && batch.created_records
      results[:saved] = Hash[batch.created_records.map {|logical, real_uri|
                               [logical, [real_uri, JSONModel.parse_reference(real_uri)[:id]]]}]
    end

    if last_error
      results[:errors] = ["Server error: #{last_error}"]
      Log.error(last_error.backtrace.join("\n"))
    end


    ticker.log("RESULTS: #{results.inspect}")
  end

end
