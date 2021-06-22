require_relative "../../model/enumeration"
require_relative "crud_helpers"
require_relative "bulk_import_mixins"

class CvList
  include CrudHelpers

  @list = []
  @list_hash = {}
  @which = ""
  @current_user

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
    raise Exception.new(I18n.t("bulk_import.error.enum", :label => label, :which => @which)) if !v
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
end
