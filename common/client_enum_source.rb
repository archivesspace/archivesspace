require "jsonmodel"
require "memoryleak"

class ClientEnumSource

  def initialize
    MemoryLeak::Resources.define(:enumerations, proc {
                                   JSONModel::Client::EnumSource.fetch_enumerations
                                 }, 300)
  end


  def valid?(name, value)
    values_for(name).include?(value)
  end
  
  def editable?(name)
    MemoryLeak::Resources.get(:enumerations).fetch(name).editable?
  end


  def values_for(name)
    MemoryLeak::Resources.get(:enumerations).fetch(name)
  end
  
  def default_value_for(name)
    MemoryLeak::Resources.get(:enumerations)[:defaults].fetch(name)
  end

end
