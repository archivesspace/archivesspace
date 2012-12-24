class ResolverController < ApplicationController
  skip_before_filter :unauthorised_access


  def resolve_edit
    if params.has_key? :uri
      resolver = Resolver.new(params[:uri])
      redirect_to resolver.edit_uri
    else
      unauthorised_access
    end
  end


  def resolve_readonly
    if params.has_key? :uri
      resolver = Resolver.new(params[:uri])
      redirect_to resolver.view_uri
    else
      unauthorised_access
    end
  end


end