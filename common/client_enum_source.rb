require "jsonmodel"
require "memoryleak"

class ClientEnumSource

  def initialize
    MemoryLeak::Resources.define(:enumerations, proc {
                                   JSONModel::Client::EnumSource.fetch_enumerations
                                 }, 300)
  end


  def valid?(name, value)
    values_for(name).include?(value) ||
      (JSONModel.allow_suppressed_enum_values? && suppressed_values_for(name).include?(value))
  end

  def editable?(name)
    if MemoryLeak::Resources.get(:enumerations).fetch(name).respond_to?(:editable?)
      MemoryLeak::Resources.get(:enumerations).fetch(name).editable?
    else
      false
    end
  end


  def values_for(name)
    MemoryLeak::Resources.get(:enumerations).fetch(name)
  end

  def suppressed_values_for(name)
    MemoryLeak::Resources.get(:enumerations)[:suppressed].fetch(name, [])
  end

  def any_suppressed_values?
    !MemoryLeak::Resources.get(:enumerations)[:suppressed].empty?
  end

  def default_value_for(name)
    MemoryLeak::Resources.get(:enumerations)[:defaults].fetch(name)
  end

end
