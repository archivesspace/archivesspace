# prepare an import job run: orchestrates converting the input file's records,
# runs the job and gathers its log output, handling any errors.

[File.expand_path("..", File.dirname(__FILE__)),
 *ASUtils.find_local_directories('backend')].each do |prefix|
  Dir.glob(File.join(prefix, "converters", "*.rb")).sort.each do |file|
    require File.absolute_path(file)
  end
end

require_relative 'streaming_import'


class Ticker

  def initialize(job)
    @job = job
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


class BatchImportRunner

  def initialize(job, import_canceled)
    @job = job
    @import_canceled = import_canceled
  end


  def run
    ticker = Ticker.new(@job)

    last_error = nil
    batch = nil
    success = false

    filenames = ASUtils.json_parse(@job.filenames || "[]")

    # Wrap the import in a transaction if the DB supports MVCC
    begin
      DB.open(DB.supports_mvcc?,
              :retry_on_optimistic_locking_fail => true) do

        begin
          @job.job_files.each_with_index do |input_file, i|
            ticker.log(("=" * 50) + "\n#{filenames[i]}\n" + ("=" * 50)) if filenames[i]
            converter = Converter.for(@job.import_type, input_file.file_path)
            begin
              converter.run

              File.open(converter.get_output_path, "r") do |fh|
                RequestContext.open(:create_enums => true,
                                    :current_username => @job.owner.username,
                                    :repo_id => @job.repo_id) do
                  batch = StreamingImport.new(fh, ticker, @import_canceled)
                  batch.process
                  log_created_uris(batch)
                  success = true
                end
              end
            ensure
              converter.remove_files
            end
          end
        rescue ImportCanceled
          raise Sequel::Rollback
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
    end

    if last_error
      
      if  last_error.respond_to?(:errors)
        ticker.log("Error: #{last_error}") if last_error.errors.empty?
        last_error.errors.each_pair { |k,v| ticker.log("\t#{k.to_s} : #{v.join(' -- ')}" ) }
        ticker.log("\n\n For #{ last_error.object_context.class }: \n #{ last_error.object_context  }") unless last_error.object_context.nil? 
        ticker.log("\n\nIn : \n #{ CGI.escapeHTML( last_error.import_context ) } ") if last_error.import_context
        ticker.log("\n\n") 
      else
        ticker.log("Error: #{last_error}")
      end
      raise last_error
    end
  end


  private

  def log_created_uris(batch)
    if batch.created_records
      DB.open do |db|
        @job.record_created_uris(batch.created_records.values)
      end
    end
  end

end
