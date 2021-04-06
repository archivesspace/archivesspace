require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Using parameterize for repository slugs that are not all digits")

    self[:repository].all.each do |r|
      # slugs that start with __ are all digits and should not go through parameterize
      # remove em and en dashes prior to parameterizing
      unless r[:slug].match(/^__/)
        slug = r[:slug].gsub(/[\u2013-\u2014]/, "").parameterize
      end
      self[:repository].where(:id => r[:id]).update(:slug => slug)
    end

  end
end
