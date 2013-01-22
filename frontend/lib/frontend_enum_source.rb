require "jsonmodel"
require "memoryleak"

class FrontendEnumSource

  def initialize
    MemoryLeak::Resources.define(:enumerations, proc {
                                   JSONModel::Client::EnumSource.fetch_enumerations
                                 }, 300)
  end


  def values_for(name)
    MemoryLeak::Resources.get(:enumerations).fetch(name)
  end

end
