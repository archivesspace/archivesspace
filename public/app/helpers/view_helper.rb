module ViewHelper
	# returns repo URL via slug if defined, via ID it not.
	def repository_base_url(result)
		if result['slug']
			url = "repositories/" + result['slug']
		else
			url = result['uri']
		end

		return url
	end
end