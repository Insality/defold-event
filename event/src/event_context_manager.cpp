#define LIB_NAME "EventContextManager"
#define MODULE_NAME "event_context_manager"

#include <dmsdk/sdk.h>

static int get_context(lua_State* L) {
	DM_LUA_STACK_CHECK(L, 1); // Expect for one return value

	if (!dmScript::IsInstanceValid(L)) { // Check if current script instance is valid
		dmLogError("Script instance is not set");
		return DM_LUA_ERROR("Script instance is not set");
	}

	dmScript::GetInstance(L); // Add current_instance to stack

	return 1;
}

static int set_context(lua_State* L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);

	// Stack: { new_instance }
	DM_LUA_STACK_CHECK(L, -1);

	dmScript::GetInstance(L); // Stack: { new_instance, current_instance }
	lua_insert(L, -2); // Stack: { current_instance, new_instance }

	dmScript::SetInstance(L); // Stack: { current_instance }
	if (!dmScript::IsInstanceValid(L)) { // Check if new_instance is valid
		dmScript::SetInstance(L); // Stack: {}
		return DM_LUA_ERROR("Instance is not valid");
	}

	lua_pop(L, 1); // Stack: {}
	return 0;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] = {
	{"get", get_context},
	{"set", set_context},
	{0, 0}
};

static void LuaInit(lua_State* L) {
	int top = lua_gettop(L);

	luaL_register(L, MODULE_NAME, Module_methods);
	lua_pop(L, 1);

	assert(top == lua_gettop(L));
}

static dmExtension::Result Initialize(dmExtension::Params* params) {
	LuaInit(params->m_L);
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(EventContextManager, LIB_NAME, 0, 0, Initialize, 0, 0, 0)
