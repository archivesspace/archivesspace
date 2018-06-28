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

	def resource_base_url(result)
		if result.json['slug']
			url = "resources/" + result.json['slug']
		else
			url = result['uri']
		end

		return url
	end

	def digital_object_base_url(result)
		if result.json['slug']
			url = "digital_objects/" + result.json['slug']
		else
			url = result['uri']
		end

		return url
	end

	def accession_base_url(result)
		if result.json['slug']
			url = "accessions/" + result.json['slug']
		else
			url = result['uri']
		end

		return url
	end

	def subject_base_url(result)
		if result.json['slug']
			url = "subjects/" + result.json['slug']
		else
			url = result['uri']
		end

		return url
	end
end