module SlugHelpers
  def self.get_id_from_slug(slug, controller, action)
  	rec, table = case controller

  	# based on the controller/action, query the right table for the slug
  	when "repositories"
  		[Repository.where(:slug => slug).first, "repository"]
  	end

  	# BINGO!
  	if rec
  		return [rec[:id], table]

  	# Always return -1 if we can't find that slug
  	else
  		return [-1, table]
  	end
  end
end