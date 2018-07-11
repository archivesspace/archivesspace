require_relative 'indexer_common'
require 'net/http'

class RealtimeIndexer < IndexerCommon

  def initialize(backend_url, should_continue)
    super(backend_url)

    @backend_url = backend_url
    @should_continue = should_continue
  end

  def get_updates(last_sequence = 0)

    resolve_params = resolved_attributes.map {|a| "resolve[]=#{a}"}.join("&")

    response = do_http_request(URI.parse(@backend_url),
                               Net::HTTP::Get.new("/update-feed?last_sequence=#{last_sequence}&#{resolve_params}"))

    if response.code != '200'
      raise "Indexing error: #{response.body}"
    end

    ASUtils.json_parse(response.body)
  end


  def run_index_round(last_sequence)
    next_sequence = last_sequence
    begin
      login

      # Blocks until something turns up
      updates = get_updates(last_sequence)

      if !updates.empty?

        # Pick out updates that represent deleted records
        deletes = updates.find_all { |update| update['record'] == 'deleted' }

        # Add the records that were created/updated
        index_records(updates - deletes)

        # Delete records that were deleted
        delete_records(deletes.map { |record| record['uri'] })

        send_commit(:soft)
        next_sequence = updates.last['sequence']
      end
    rescue Timeout::Error
      # Doesn't matter...
    rescue
      reset_session
      Log.error("#{$!.inspect}")
      Log.error($@.join("\n"))
      sleep 5
    end

    next_sequence
  end

  def run
    last_sequence = 0

    while @should_continue.call
     last_sequence = run_index_round(last_sequence) unless paused?   
    end

  end

end
