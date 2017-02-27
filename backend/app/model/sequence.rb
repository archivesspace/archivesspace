class Sequence

  # Run a separate DB connection pool to allow sequences to commit independently
  # to the caller.  The separate pool also prevents deadlocks that would occur
  # if caller threads tried to take a second connection from the main DB
  # connection pool.
  db_connections = [(AppConfig[:db_max_connections] / 5.0).floor,
                    5].min

  @@pool = DB::DBPool.new(db_connections, :skip_utf8_check => true).connect


  def self.init(sequence, value)
    @@pool.open(true) do |db|
      db[:sequence].insert(:sequence_name => sequence.to_s, :value => value)
    end
  end

  def self.get(sequence)
    Thread.current[:initialised_sequences] ||= {}

    needs_sequence_init = !Thread.current[:initialised_sequences][sequence]

    if needs_sequence_init
      @@pool.open(true) do |db|
        @@pool.attempt {
          init(sequence, 0)
          return 0
        }.and_if_constraint_fails {
          # Sequence is already defined, which is fine
        }
      end

      Thread.current[:initialised_sequences][sequence] = true
    end

    # If we make it to here, the sequence already exists and needs to be incremented
    1000.times do
      new_value = nil

      updated_count = @@pool.open do |db|
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
