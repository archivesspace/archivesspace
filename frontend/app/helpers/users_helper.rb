module UsersHelper
  def sort_pointer(field, params, default)
    direction = params['direction']
    sort = params['sort']
    return default unless direction && sort
    return '' unless sort == field.to_s

    direction == 'asc' ? '&#x25B2;' : '&#x25BC;'
  end

  def sort_direction(field, params, default)
    direction = params['direction']
    return 'desc' unless direction

    sort = params['sort']
    return default if sort != field.to_s

    direction == 'asc' ? 'desc' : 'asc'
  end
end
