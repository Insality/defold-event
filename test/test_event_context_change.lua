return function()
	local events = {} --[[@as events]]

	describe("Event Context Change", function()
		before(function()
			events = require("event.events")
		end)

		it("Get position from GO in GUI", function()
			local go_position = events.trigger("get_go_position", "go")
			-- Value is from go_context_script
			assert(go_position)
			assert(go_position.x == 42)
			assert(go_position.y == 42)
		end)

		it("Get value from GO script", function()
			local go_value = events.trigger("get_go_value", "go")
			-- Value is from go_context_script
			assert(go_value == "secret_value_go")
		end)
	end)
end
