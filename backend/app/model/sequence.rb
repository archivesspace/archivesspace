class Sequence
  # DEPRECATED: this is dead code since ArchivesSpace v2

  QUEUE = java.util.concurrent.ArrayBlockingQueue.new(1024)

  def self.init(sequence, value)
    result = java.util.concurrent.CompletableFuture.new
    QUEUE.add({action: :init, sequence: sequence, value: value, result: result})
    result.get
    nil
  end

  def self.get(sequence)
    result = java.util.concurrent.CompletableFuture.new
    QUEUE.add({action: :get, sequence: sequence, result: result})
    result.get
  end

  def self._handle_get(request, initialised_sequences)
    sequence = request[:sequence]
    DB.open(true) do |db|
      if !initialised_sequences[sequence]
        initialised_sequences[sequence] = true

        DB.attempt {
          db[:sequence].insert(:sequence_name => sequence.to_s, :value => 0)
          request[:result].complete(0)
          return
        }.and_if_constraint_fails {
          # Sequence is already defined, which is fine
        }
      end

      # If we make it to here, the sequence already exists and needs to be incremented
      1000.times do
        old_value = db[:sequence].filter(:sequence_name => sequence.to_s).get(:value)
        updated_count = db[:sequence].filter(:sequence_name => sequence.to_s, :value => old_value).
                          update(:value => old_value + 1)

        if updated_count == 0
          # Need to retry
          sleep(0.01)
        elsif updated_count == 1
          request[:result].complete(old_value + 1)
          return
        else
          Log.error("Unrecognised response from SQL update when generating next element in sequence '#{sequence}': #{updated_count}")
        end
      end

      Log.error("Gave up trying to generate a sequence number for: '#{sequence}'")
      request[:result].completeExceptionally(java.lang.RuntimeException.new("Gave up trying to generate a sequence number for: '#{sequence}'"))
    end
  end

  Thread.new do
    initialised_sequences = {}

    while request = QUEUE.take
      begin
        if request[:action] == :init
          DB.open(true) do |db|
            DB.attempt {
              db[:sequence].insert(:sequence_name => request[:sequence].to_s, :value => request[:value])
            }.and_if_constraint_fails {
              # Sequence is already defined, which is fine
            }

            request[:result].complete(nil)
          end
        elsif request[:action] == :get
          _handle_get(request, initialised_sequences)
        else
          request[:result].completeExceptionally(java.lang.RuntimeException.new("Unrecognised action"))
        end
      rescue
        Log.error("Error while generating sequence: $!")
        Log.exception($!)
        request[:result].completeExceptionally(java.lang.RuntimeException.new("Unexpected error"))
      end
    end

  end

end
