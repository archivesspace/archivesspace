require_relative 'utils'

Sequel.migration do
  up do
      # there is nothing to see here
      # once there were many mysql stored procedures
      # now they are gone
      # see a8b2043a41f2b18058919e2f28c8685eb1d4f73d if you want to know why
  end
end
