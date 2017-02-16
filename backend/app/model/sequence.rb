class Sequence

  def self.init(sequence, value)
    DB.open(true) do |db|
      db[:sequence].insert(:sequence_name => sequence.to_s, :value => value)
    end
  end


  def self.get(sequence)
    Thread.current[:initialised_sequences] ||= {}

    needs_sequence_init = !Thread.current[:initialised_sequences][sequence]

    future = Thread.new do
      handle_get(sequence, needs_sequence_init)
    end

    future.value
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
      old_value = DB.open do |db|
        db[:sequence].filter(:sequence_name => sequence.to_s).get(:value)
      end

      updated_count = DB.open do |db|
        db[:sequence].filter(:sequence_name => sequence.to_s, :value => old_value).
          update(:value => old_value + 1)
      end

      if updated_count == 0
        # Need to retry
        sleep(0.01)
      elsif updated_count == 1
        puts "Got sequence number: #{old_value + 1} for #{sequence.to_s}"
        return old_value + 1
      else
        raise SequenceError.new("Unrecognised response from SQL update when generating next element in sequence '#{sequence}': #{updated_count}")
      end
    end

    raise SequenceError.new("Gave up trying to generate a sequence number for: '#{sequence}'")
  end

end
