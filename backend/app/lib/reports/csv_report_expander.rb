class CsvReportExpander

	def initialize(data, job)
		@data = data
		@job = job
	end

	def expand_csv
		fix_json_columns(0, @data[0].size)
		@data
	end

	private

	def json_keys(cell)
		begin
			data = ASUtils.json_parse(cell)
		rescue
			data = nil
		end
		if data.is_a?(Array) && data.size > 0
			data[0].keys
		else
			nil
		end
	end

	def find_json_columns(start_range, end_range)
		json_columns = {}
		(start_range...end_range).each do |column|

			row = 1

			while row < @data.size
				begin
					if @data[row][column] == nil || @data[row][column] == ''
						row += 1
					else
						break
					end
				rescue
					row += 1
				end
			end

			if row < @data.size
				keys = json_keys(@data[row][column])
				json_columns[column] = keys if keys
			end
		end

		json_columns
	end

	def fix_json_columns(start_range, end_range)
		json_columns = find_json_columns(start_range, end_range)

		cols_added = 0

		json_columns.keys.each do |column|
			adj_col = column + cols_added
			header_keys = []

			json_columns[column].each do |header|
				header_keys.push("#{@data[0][adj_col]}_#{header}")
			end
			@data[0] = @data[0][0...adj_col] + header_keys +
				@data[0][adj_col + 1...@data[0].size]

			new_data = []
			(1...@data.size).each do |row|
				if @data[row][adj_col] == nil || @data[row][adj_col] == ''
					empty_cells = [nil] * json_columns[column].size
					new_data.push(@data[row][0...adj_col] + empty_cells +
						@data[row][adj_col + 1...@data[row].size])
					next
				end

				cell_data = ASUtils.json_parse(@data[row][adj_col])
				cell_data.each do |item|
					new_row = @data[row][0...adj_col]
					json_columns[column].each do |key|
						if item[key].is_a?(Array)
							new_row += [ASUtils.to_json(item[key])]
						else
							new_row += [item[key]]
						end
					end
					new_row += @data[row][adj_col + 1...@data[row].size]
					new_data.push(new_row)
				end
			end

			@data = [@data[0]] + new_data

			cols_added += fix_json_columns(
				adj_col, adj_col + json_columns[column].size)
			cols_added += json_columns[column].size - 1
		end

		cols_added
	end
end