def menu_lists
  # TODO: Check the registry to see if there are any schemas
  super + [ { :type => 'schema', :title => 'Schemas', :search_title => 'Schemas' } ]
end
