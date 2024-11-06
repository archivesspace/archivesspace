require_relative "../../model/enumeration"
require_relative "crud_helpers"
require_relative "bulk_import_mixins"

class CvList
  include CrudHelpers


  # for these enums, don't throw an error if values are referenced
  CREATE_NEW_VALUES_FOR = ["instance_instance_type", "container_type"]

  @list = []
  @list_hash = {}
  @which = ""
  @current_user

  attr_reader :which

  def initialize(which, current_user)
    @which = which
    @current_user = current_user
    renew
  end

  def value(label)
    if @list_hash[label]
      v = @list_hash[label]
    elsif @list.index(label)
      v = label
    end

    if !v and !CvList::CREATE_NEW_VALUES_FOR.include?(@which)
      raise Exception.new(I18n.t("bulk_import.error.enum", label: label, which: @which, valid_values: @list.join(', ')))
    end

    v
  end

  def length
    @list.length
  end

  def renew
    @list = []
    list_hash = {}
    enums = handle_raw_listing(Enumeration, { :name => @which }, @current_user)
    enums[0]["values"].each do |v|
      if !v["suppressed"]
        trans = I18n.t("enumerations.#{@which}.#{v}", default: v)
        if !list_hash[trans]
          list_hash[trans] = v
          @list.push v
        else
          Log.warn(I18n.t("bulk_import.warn.dup", :which => @which, :trans => trans, :used => list_hash[trans]))
        end
      end
    end
    @list_hash = list_hash
  end

  def add_value_to_enum(new_value)
    enum = Enumeration.find(:name => @which)
    if enum.editable === 1 || enum.editable == true
      unless @validate_only
        new_position = enum.enumeration_value.length + 1
        enum.add_enumeration_value(:value => new_value, :position => new_position)
        renew
      end
    end
  end
end
