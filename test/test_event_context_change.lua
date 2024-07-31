return function()
	local events = {} --[[@as events]]

	describe("Event Context Change", function()
		before(function()
			events = require("event.events")
		end)

		it("Get position from GO in GUI", function()
			local object = factory.create("#go_context_object", vmath.vector3(42, 42, 0))

			local go_position = events.trigger("get_go_position", "go")
			-- Value is from go_context_script
			assert(go_position)
			assert(go_position.x == 42)
			assert(go_position.y == 42)

			go.delete(object)
		end)

		it("Get value from GO script", function()
			local object = factory.create("/test#go_context_object")

			local go_value = events.trigger("get_go_value", "go")
			-- Value is from go_context_script
			assert(go_value == "secret_value_go")

			go.delete(object)
		end)

		it("Get size from GUI", function()
			local object = factory.create("#gui_context_object")

			local gui_size = events.trigger("get_gui_size")
			assert(gui_size)
			assert(gui_size.x == 200)
			assert(gui_size.y == 100)

			go.delete(object)
		end)
	end)
end
