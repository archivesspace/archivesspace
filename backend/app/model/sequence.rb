class Sequence

  # We run sequence generation in separate threads to allow us to commit
  # transactions independently of the caller.  Otherwise the nested transaction
  # is subsumed by the parent one, which doesn't work.
  @@pool = java.util.concurrent.ThreadPoolExecutor.new(10,
                                                       10,
                                                       0,
                                                       java.util.concurrent.TimeUnit::MILLISECONDS,
                                                       java.util.concurrent.ArrayBlockingQueue.new(1024))

  @@submit = @@pool.java_method(:submit, [java.util.concurrent.Callable])


  def self.init(sequence, value)
    DB.open(true) do |db|
      db[:sequence].insert(:sequence_name => sequence.to_s, :value => value)
    end
  end

  def self.get(sequence)
    Thread.current[:initialised_sequences] ||= {}

    needs_sequence_init = !Thread.current[:initialised_sequences][sequence]

    future = @@submit.call(proc { handle_get(sequence, needs_sequence_init)})

    begin
      future.get
    ensure
      Thread.current[:initialised_sequences][sequence] = true
    end
  end

  def self.handle_get(sequence, needs_sequence_init)
    if needs_sequence_init
      DB.open(true) do |db|
        DB.attempt {
          init(sequence, 0)
          return 0
        }.and_if_constraint_fails {
          # Sequence is already defined, which is fine
        }
      end
    end

    # If we make it to here, the sequence already exists and needs to be incremented
    1000.times do
      new_value = nil

      updated_count = DB.open do |db|
        old_value = db[:sequence].filter(:sequence_name => sequence.to_s).get(:value)
        new_value = old_value + 1

        db[:sequence].filter(:sequence_name => sequence.to_s, :value => old_value).
          update(:value => new_value)
      end

      if updated_count == 0
        # Need to retry
        sleep(0.001)
      elsif updated_count == 1
        return new_value
      else
        raise SequenceError.new("Unrecognised response from SQL update when generating next element in sequence '#{sequence}': #{updated_count}")
      end
    end

    raise SequenceError.new("Gave up trying to generate a sequence number for: '#{sequence}'")
  end

end
