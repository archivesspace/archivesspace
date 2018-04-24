require_relative 'utils'
require "ASModel"

Sequel.migration do
  up do
    Resource.any_repo.all.each do |r|
      puts r[:id]
    end
  end
end