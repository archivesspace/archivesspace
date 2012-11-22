class Sequence

  def self.init(sequence, value)
    DB.open(true) do |db|
      begin
        db[:sequence].insert(:sequence_name => sequence.to_s, :value => value)
      end
    end
  end


  def self.get(sequence)
    DB.open(true) do |db|

      begin
        init(sequence, 0)
        return 0
      rescue Sequel::DatabaseError => e
        if DB.is_integrity_violation(e)
          # Sequence is already defined, which is fine
        end
      end


      # If we make it to here, the sequence already exists and needs to be incremented
      100.times do
        old_value = db[:sequence].filter(:sequence_name => sequence.to_s).get(:value)
        updated_count = db[:sequence].filter(:sequence_name => sequence.to_s, :value => old_value).
                                      update(:value => old_value + 1)

        if updated_count == 0
          # Need to retry
          sleep 0.5
        elsif updated_count == 1
          return old_value + 1
        else
          raise SequenceError.new("Unrecognised response from SQL update when generating next element in sequence '#{sequence}': #{updated_count}")
        end
      end

      raise SequenceError.new("Gave up trying to generate a sequence number for: '#{sequence}'")
    end
  end

end
