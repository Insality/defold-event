return function()
	describe("Event mode (pcall / xpcall / none)", function()
		local event ---@type event

		before(function()
			event = require("event.event")
		end)

		after(function()
			event.set_mode("pcall")
		end)

		it("pcall mode: error in callback is caught, trigger does not rethrow", function()
			event.set_mode("pcall")

			local test_event = event.create()
			test_event:subscribe(function()
				error("pcall test error")
			end)

			local ok, err = pcall(function()
				test_event:trigger()
			end)

			assert(ok == true)
			assert(err == nil)
		end)

		it("pcall mode: error in callback is logged", function()
			event.set_mode("pcall")

			local logged = false
			local logger = {
				trace = function() end,
				debug = function() end,
				info = function() end,
				warn = function() end,
				error = function() logged = true end,
			}
			event.set_logger(logger)

			local test_event = event.create()
			test_event:subscribe(function()
				error("pcall log test")
			end)
			test_event:trigger()

			assert(logged == true)
		end)

		it("xpcall mode: error in callback is caught, trigger does not rethrow", function()
			event.set_mode("xpcall")

			local test_event = event.create()
			test_event:subscribe(function()
				error("xpcall test error")
			end)

			local ok, err = pcall(function()
				test_event:trigger()
			end)

			assert(ok == true)
			assert(err == nil)
		end)

		it("xpcall mode: error in callback is logged with message", function()
			event.set_mode("xpcall")

			local logged_msg = nil
			local logger = {
				trace = function() end,
				debug = function() end,
				info = function() end,
				warn = function() end,
				error = function(_, msg) logged_msg = msg end,
			}
			event.set_logger(logger)

			local err_msg = "xpcall log test"
			local test_event = event.create()
			test_event:subscribe(function()
				error(err_msg)
			end)
			test_event:trigger()

			assert(logged_msg and tostring(logged_msg):find(err_msg))
		end)

		it("pcall mode: trigger returns nil when only callback errors", function()
			event.set_mode("pcall")

			local test_event = event.create()
			test_event:subscribe(function()
				error("pcall error")
			end)

			local result = test_event:trigger()
			assert(result == nil)
		end)

		it("pcall mode: trigger returns last successful result when later callback errors", function()
			event.set_mode("pcall")

			local test_event = event.create()
			test_event:subscribe(function()
				return 42
			end)
			test_event:subscribe(function()
				error("second callback error")
			end)

			local result = test_event:trigger()
			assert(result == 42)
		end)

		it("xpcall mode: trigger returns nil when only callback errors", function()
			event.set_mode("xpcall")

			local test_event = event.create()
			test_event:subscribe(function()
				error("xpcall error")
			end)

			local result = test_event:trigger()
			assert(result == nil)
		end)

		it("xpcall mode: trigger returns last successful result when later callback errors", function()
			event.set_mode("xpcall")

			local test_event = event.create()
			test_event:subscribe(function()
				return "ok"
			end)
			test_event:subscribe(function()
				error("second callback error")
			end)

			local result = test_event:trigger()
			assert(result == "ok")
		end)

		it("none mode: error in callback rethrows from trigger", function()
			event.set_mode("none")

			local test_event = event.create()
			local err_msg = "none mode error"
			test_event:subscribe(function()
				error(err_msg)
			end)

			local ok, err = pcall(function()
				test_event:trigger()
			end)

			assert(ok == false)
			assert(err and tostring(err):find(err_msg))
		end)

		it("unknown mode defaults to pcall: error is caught", function()
			event.set_mode("invalid_mode_typo")

			local test_event = event.create()
			test_event:subscribe(function()
				error("unknown mode error")
			end)

			local ok, err = pcall(function()
				test_event:trigger()
			end)

			assert(ok == true)
			assert(err == nil)
		end)

		it("xpcall: trigger with context passes all args (nil in middle)", function()
			event.set_mode("xpcall")

			local test_event = event.create()
			local ctx = {}
			local ra, rb, rc
			local f = function(self, ...)
				ra, rb, rc = ...
			end

			test_event:subscribe(f, ctx)
			test_event:trigger(1, nil, 3)

			assert(ra == 1)
			assert(rb == nil)
			assert(rc == 3)
		end)

		it("xpcall: trigger without context passes all args (nil in middle)", function()
			event.set_mode("xpcall")

			local test_event = event.create()
			local ra, rb, rc
			local f = function(...)
				ra, rb, rc = ...
			end

			test_event:subscribe(f)
			test_event:trigger(1, nil, 3)

			assert(ra == 1)
			assert(rb == nil)
			assert(rc == 3)
		end)

		it("none: trigger with context passes all args (nil in middle)", function()
			event.set_mode("none")

			local test_event = event.create()
			local ctx = {}
			local ra, rb, rc
			local f = function(self, ...)
				ra, rb, rc = ...
			end

			test_event:subscribe(f, ctx)
			test_event:trigger(1, nil, 3)

			assert(ra == 1)
			assert(rb == nil)
			assert(rc == 3)
		end)

		it("none: trigger without context passes all args (nil in middle)", function()
			event.set_mode("none")

			local test_event = event.create()
			local ra, rb, rc
			local f = function(...)
				ra, rb, rc = ...
			end

			test_event:subscribe(f)
			test_event:trigger(1, nil, 3)

			assert(ra == 1)
			assert(rb == nil)
			assert(rc == 3)
		end)

		it("none: cross-context works", function()
			event.set_mode("none")

			local events = require("event.events")
			local object = factory.create("#go_context_object", vmath.vector3(42, 42, 0))

			local go_position = events.trigger("get_go_position", "go")
			assert(go_position)
			assert(go_position.x == 42)
			assert(go_position.y == 42)

			go.delete(object)
		end)
	end)
end
