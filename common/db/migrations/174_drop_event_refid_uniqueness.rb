require_relative 'utils'

Sequel.migration do

  up do
    # this is coded defensively in case fix was pre-applied
    if self.indexes(:event).values.map { |x| x[:columns]}.include?([:refid])
      alter_table(:event) do
        drop_index :refid, name: 'refid'
      end
    end
  end

  down do
  end

end
