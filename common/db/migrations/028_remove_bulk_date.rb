require_relative 'utils'

Sequel.migration do


  # this migration was a mistake and born out of a misunderstood feature 
  # request. Apologize if you already ran it, but it only removed the bulk_date
  # value from the enum lists. next migration resolves this. 
  up do
  end


  down do
  end

end
