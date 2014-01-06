module ResolverHelper

  def resolve_readonly_link_to(label, uri)
    link_to label, :controller => :resolver, :action => :resolve_readonly, :uri => uri
  end


  def resolve_edit_link_to(label, uri)
    link_to label, :controller => :resolver, :action => :resolve_edit, :uri => uri
  end

end