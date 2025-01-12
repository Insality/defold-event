-- Open ../export_doc/doc.json and parse to lua table

local json = require("ldoc_exporter.json")

local M = {}

function M.read_doc(filepath)
	local file = io.open("./export_doc/doc.json", "r")
	if not file then
		error("File not found")
	end

	return json.decode(file:read("*all"))
end

function M.parse_doc(doc_table)
	local parsed = {}

	for index = 1, #doc_table do
		local name = doc_table[index].name
		if name == "event" or name == "events" then
			parsed[name] = doc_table[index]
		end
	end

	for module_name, data in pairs(parsed) do
		local functions = {}
		local fields = data.fields
		for field_index = 1, #fields do
			local field = fields[field_index]
			if (field.type == "setmethod" or field.type == "setfield") and field.visible == "public" then
				local func = {}
				func.name = field.name or "UNKNOWN"
				func.description = field.rawdesc or "UNKNOWN"
				func.type = field.type
				func.args = {}
				func.returns = {}
				functions[field.name] = func

				-- Print args
				if field.extends then
					local args = field.extends.args
					if args then
						for arg_index = 1, #args do
							local arg = args[arg_index]
							--print(arg.name, arg.view, arg.rawdesc)
							if arg.type == "self" then
								-- Mark as self
							elseif arg.type == "..." then
								local arg_data = {
									name = "...",
									description = "vararg",
									type = "..."
								}
								table.insert(func.args, arg_data)
							else
								local arg_data = {
									name = arg.name or "UNKNOWN",
									description = arg.rawdesc or "UNKNOWN",
									type = arg.view
								}
								table.insert(func.args, arg_data)
							end
						end
					end

					local returns = field.extends.returns
					if returns then
						for return_index = 1, #returns do
							local return_val = returns[return_index]
							--print(return_val.name, return_val.view, return_val.rawdesc)
							local return_data = {
								name = return_val.name or "UNKNOWN",
								description = return_val.rawdesc or "UNKNOWN",
								type = return_val.view
							}
							table.insert(func.returns, return_data)
						end
					end
				end
			end
		end

		parsed[module_name] = functions
	end

	M.print(parsed)

	return parsed
end


function M.print(parsed_data)
	for module_name, data in pairs(parsed_data) do
		print("")
		print("Module: " .. module_name)
		for func_name, func_data in pairs(data) do
			print("----")
			print(string.format("Function: %s [%s]", func_name, func_data.type))
			--print("Function: " .. func_name)
			--print("Description: " .. func_data.description)
			--print("Type: " .. func_data.type)
			print("Args:")
			for arg_index = 1, #func_data.args do
				local arg = func_data.args[arg_index]
				print(string.format("  - %s [%s]: %s", arg.name, arg.type, arg.description))
			end
			print("Returns:")
			for return_index = 1, #func_data.returns do
				local return_val = func_data.returns[return_index]
				print(string.format("  - %s [%s]: %s", return_val.name, return_val.type, return_val.description))
				--print("  - Name: " .. return_val.name)
				--print("  - Description: " .. return_val.description)
				--print("  - Type: " .. return_val.type)
			end
		end
	end
end


M.parse_doc(M.read_doc("./export_doc/doc.json"))


return M